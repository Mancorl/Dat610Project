%% Q2: How do retransmissions and the latency budget affect reliability?
% Based on the MathWorks "NR PDSCH Throughput" example [5], reconfigured to
% use the SAME link as Q1, Q3 and Q4 (Table I):
%   3.5 GHz (n78), 30 kHz SCS, 51 RB (20 MHz), 1x1 antennas, 1 layer,
%   R = 490/1024, 12 LDPC iterations (normalized min-sum), 16 HARQ
%   processes, 3 km/h, TDL-C 300 ns (urban) / TDL-D 30 ns (rural),
%   perfect channel estimation (as in Q3), 100 frames per SNR point.
%
% Swept here: modulation (QPSK, 16QAM, 64QAM, 256QAM) inside this script,
% and, from Q2_runall.m, the maximum number of transmissions
% Q2_NTX in {1,2,4,8} and the environment Q2_ENV in {"urban","rural"}.
%
% Requires the helper files shipped with the MathWorks example
% (HARQEntity.m, hSVDPrecoders.m, hSkipWeakTimingOffset.m) on the path.

%% Sweep parameters (set by Q2_runall.m, defaults for a single run)
if ~exist("Q2_NTX","var"), Q2_NTX = 4;       end   % max transmissions per TB
if ~exist("Q2_ENV","var"), Q2_ENV = "urban"; end   % "urban" or "rural"

%% Simulation length and SNR points
simParameters = struct();
simParameters.NFrames = 100;        % 100 x 10 ms frames = 2000 slots per point
% 1x1 has no array gain, so the range is wider than Table I (0-16 dB) in
% order to take QPSK to 0 % and 256-QAM to 100 % throughput.
simParameters.SNRIn   = -10:2:30;   % dB
numSNRPoints = numel(simParameters.SNRIn);

simParameters.UseGPU = "auto";
simParameters.PerfectChannelEstimator = true;    % same as Q3 (decoding chain only)
simParameters.DisplaySimulationInformation = false;

%% Carrier (Table I)
simParameters.Carrier = nrCarrierConfig;
simParameters.Carrier.NSizeGrid = 51;            % 51 RB = 20 MHz at 30 kHz
simParameters.Carrier.SubcarrierSpacing = 30;    % 0.5 ms slot
simParameters.Carrier.CyclicPrefix = "Normal";
simParameters.Carrier.NCellID = 1;

%% PDSCH / DL-SCH (Table I)
simParameters.PDSCH = nrPDSCHConfig;
simParameters.PDSCHExtension = struct();
simParameters.PDSCH.PRBSet = 0:simParameters.Carrier.NSizeGrid-1;
simParameters.PDSCH.SymbolAllocation = [0, simParameters.Carrier.SymbolsPerSlot];
simParameters.PDSCH.MappingType = "A";
simParameters.PDSCH.NID  = simParameters.Carrier.NCellID;
simParameters.PDSCH.RNTI = 1;
simParameters.PDSCH.VRBToPRBInterleaving = 0;
simParameters.PDSCH.VRBBundleSize = 4;
simParameters.PDSCH.NumLayers = 1;               % 1 layer (was 2)

% DM-RS (reference-example defaults, unchanged)
simParameters.PDSCH.DMRS.DMRSTypeAPosition = 2;
simParameters.PDSCH.DMRS.DMRSLength = 1;
simParameters.PDSCH.DMRS.DMRSAdditionalPosition = 2;
simParameters.PDSCH.DMRS.DMRSConfigurationType = 2;
simParameters.PDSCH.DMRS.NumCDMGroupsWithoutData = 1;
simParameters.PDSCH.DMRS.NIDNSCID = 1;
simParameters.PDSCH.DMRS.NSCID = 0;
simParameters.PDSCH.DMRS.DMRSPortSet = [];

simParameters.PDSCH.EnablePTRS = 0;              % PT-RS off
simParameters.PDSCH.ReservedPRB{1}.SymbolSet = [];
simParameters.PDSCH.ReservedPRB{1}.PRBSet = [];
simParameters.PDSCH.ReservedPRB{1}.Period = [];

simParameters.PDSCHExtension.TargetCodeRate = 490/1024;
simParameters.PDSCHExtension.PRGBundleSize = [];
simParameters.PDSCHExtension.XOverhead = 0;
simParameters.PDSCHExtension.NHARQProcesses = 16;
simParameters.PDSCHExtension.EnableCBGTransmission = false;
simParameters.PDSCHExtension.LDPCDecodingAlgorithm = "Normalized min-sum";
simParameters.PDSCHExtension.MaximumLDPCIterationCount = 12;

%% Antennas and channel (Table I)
simParameters.NTxAnts = 1;                       % 1x1 (was 8x2 with SVD precoding)
simParameters.NRxAnts = 1;
simParameters.DataType = "single";

simParameters.CarrierFrequency = 3.5e9;          % Hz, band n78
simParameters.UESpeedKmh = 3;                    % pedestrian, as Q1 and Q3
c = physconst("LightSpeed");
simParameters.MaximumDopplerShift = (simParameters.UESpeedKmh/3.6) * ...
    simParameters.CarrierFrequency / c;          % ~9.7 Hz

switch lower(Q2_ENV)
    case "urban"                                 % NLOS
        simParameters.DelayProfile = "TDL-C";
        simParameters.DelaySpread  = 300e-9;
    case "rural"                                 % LOS
        simParameters.DelayProfile = "TDL-D";
        simParameters.DelaySpread  = 30e-9;
    otherwise
        error("Q2_ENV must be ""urban"" or ""rural"".");
end

waveformInfo = nrOFDMInfo(simParameters.Carrier);
[channel, simParameters] = createChannel(simParameters, waveformInfo);
chInfo = info(channel);
maxChDelay = chInfo.MaximumChannelDelay;

if simParameters.UseGPU == "on" || (simParameters.UseGPU == "auto" && canUseGPU)
    simParameters.Prototype = zeros(0,0,"gpuArray");
else
    simParameters.Prototype = zeros(0,0);
end

%% HARQ / latency budget
% Ntx is set by truncating or repeating the RV sequence [0 2 3 1].
% Ntx = 1 means HARQ off (a failed block is dropped after one attempt).
baseRV = [0 2 3 1];
rvSeq  = baseRV(mod(0:Q2_NTX-1, 4) + 1);
simParameters.PDSCHExtension.EnableHARQ = (Q2_NTX > 1);
maxNumCBG = 1;                                   % TB-based transmission

slotDurationMs = 1 / simParameters.Carrier.SlotsPerSubframe;   % 0.5 ms

%% Storage (one column per modulation)
modulationlist = ["QPSK" "16QAM" "64QAM" "256QAM"];
nMod = numel(modulationlist);
latencyAll    = nan(numSNRPoints, nMod);   % mean latency of delivered blocks (ms)
throughputAll = nan(numSNRPoints, nMod);   % Mbit/s (goodput, CRC-passed TB bits)
throughputPct = nan(numSNRPoints, nMod);   % % of maximum
residualAll   = nan(numSNRPoints, nMod);   % share of blocks lost after Ntx attempts
avgTxAll      = nan(numSNRPoints, nMod);   % mean transmissions per delivered block

figLat = figure; axLat = axes(figLat); hold(axLat,"on");
figThr = figure; axThr = axes(figThr); hold(axThr,"on");

%% Modulation loop
for mIdx = 1:nMod
    modulation = modulationlist(mIdx);
    simParameters.PDSCH.Modulation = modulation;

    % DL-SCH encoder / decoder
    encodeDLSCH = nrDLSCH;
    encodeDLSCH.MultipleHARQProcesses = true;
    encodeDLSCH.TargetCodeRate = simParameters.PDSCHExtension.TargetCodeRate;

    decodeDLSCH = nrDLSCHDecoder;
    decodeDLSCH.MultipleHARQProcesses = true;
    decodeDLSCH.TargetCodeRate = simParameters.PDSCHExtension.TargetCodeRate;
    decodeDLSCH.LDPCDecodingAlgorithm = simParameters.PDSCHExtension.LDPCDecodingAlgorithm;
    decodeDLSCH.MaximumLDPCIterationCount = simParameters.PDSCHExtension.MaximumLDPCIterationCount;

    simThroughput = zeros(numSNRPoints,1);
    maxThroughput = zeros(numSNRPoints,1);
    sumLatencyMs  = zeros(numSNRPoints,1);
    nDeliveredAll = zeros(numSNRPoints,1);
    residualBLER  = nan(numSNRPoints,1);
    avgTx         = nan(numSNRPoints,1);

    for snrIdx = 1:numSNRPoints
        rng("default");                      % same noise for every point
        reset(channel);                      % same fading for every point
        decodeDLSCH.reset();

        carrier    = simParameters.Carrier;
        pdsch      = simParameters.PDSCH;
        pdschextra = simParameters.PDSCHExtension;
        SNRdB      = simParameters.SNRIn(snrIdx);

        fprintf("%s, Ntx=%d, %s, %g dB\n", Q2_ENV, Q2_NTX, modulation, SNRdB);

        harqEntity  = HARQEntity(0:pdschextra.NHARQProcesses-1, rvSeq, ...
                                 pdsch.NumCodewords, maxNumCBG);
        txStartSlot = nan(1, pdschextra.NHARQProcesses);
        txCount     = zeros(1, pdschextra.NHARQProcesses);
        nDelivered = 0; nLost = 0; sumTxDelivered = 0;

        NSlots = simParameters.NFrames * carrier.SlotsPerFrame;

        estChannelGridAnts = getInitialChannelEstimate(carrier, channel, ...
            simParameters.DataType, maxChDelay);
        newWtx = hSVDPrecoders(carrier, pdsch, estChannelGridAnts, pdschextra.PRGBundleSize);
        offset = 0;

        SNR  = 10^(SNRdB/10);
        N0   = 1/sqrt(simParameters.NRxAnts*waveformInfo.Nfft*SNR);
        nVar = N0^2*waveformInfo.Nfft;

        for nslot = 0:NSlots-1
            carrier.NSlot = nslot;
            [pdschIndices, pdschIndicesInfo] = nrPDSCHIndices(carrier, pdsch);
            trBlkSize = nrTBS(pdsch.Modulation, pdsch.NumLayers, numel(pdsch.PRBSet), ...
                pdschIndicesInfo.NREPerPRB, pdschextra.TargetCodeRate, pdschextra.XOverhead);

            pid = harqEntity.HARQProcessID + 1;

            % New transport block for this HARQ process
            if harqEntity.NewData
                trBlk = randi([0 1], trBlkSize, 1, "like", simParameters.Prototype);
                setTransportBlock(encodeDLSCH, trBlk, 0, harqEntity.HARQProcessID);
                txStartSlot(pid) = nslot;
                if harqEntity.SequenceTimeout
                    resetSoftBuffer(decodeDLSCH, 0, harqEntity.HARQProcessID);
                end
            end

            % Transmit
            codedTrBlock = encodeDLSCH(pdsch.Modulation, pdsch.NumLayers, ...
                pdschIndicesInfo.G, harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

            wtx = newWtx;
            pdschGrid = nrResourceGrid(carrier, simParameters.NTxAnts, ...
                OutputDataType=simParameters.DataType, UseGPU=simParameters.UseGPU);
            pdschSymbols = nrPDSCH(carrier, pdsch, codedTrBlock);
            [antSym, antInd] = nrPDSCHPrecode(carrier, pdschSymbols, pdschIndices, wtx);
            pdschGrid(antInd) = antSym;

            dmrsSymbols = nrPDSCHDMRS(carrier, pdsch);
            dmrsIndices = nrPDSCHDMRSIndices(carrier, pdsch);
            [antSym, antInd] = nrPDSCHPrecode(carrier, dmrsSymbols, dmrsIndices, wtx);
            pdschGrid(antInd) = antSym;

            txWaveform = nrOFDMModulate(carrier, pdschGrid);
            txWaveform = [txWaveform; zeros(maxChDelay, size(txWaveform,2))]; %#ok<AGROW>
            [rxWaveform, ofdmResponse, timingOffset] = channel(txWaveform, carrier);
            rxWaveform = rxWaveform + N0*randn(size(rxWaveform), "like", rxWaveform);

            % Receive
            if simParameters.PerfectChannelEstimator
                offset = timingOffset;
            else
                [t, mag] = nrTimingEstimate(carrier, rxWaveform, dmrsIndices, dmrsSymbols);
                offset = hSkipWeakTimingOffset(offset, t, mag);
            end
            rxGrid = nrOFDMDemodulate(carrier, rxWaveform(1+offset:end,:));
            [K, L, R] = size(rxGrid);
            if L < carrier.SymbolsPerSlot
                rxGrid = cat(2, rxGrid, zeros(K, carrier.SymbolsPerSlot-L, R));
            end

            if simParameters.PerfectChannelEstimator
                estChannelGridAnts = ofdmResponse;
                noiseEst = nVar;
                estChannelGridPorts = precodeChannelEstimate(carrier, estChannelGridAnts, permute(wtx,[2 1 3]));
            else
                [estChannelGridPorts, noiseEst] = nrChannelEstimate(carrier, rxGrid, ...
                    dmrsIndices, dmrsSymbols, "CDMLengths", pdsch.DMRS.CDMLengths);
                noiseEst = mean(noiseEst, "all");
                estChannelGridAnts = precodeChannelEstimate(carrier, estChannelGridPorts, conj(wtx));
            end
            [pdschRx, pdschHest] = nrExtractResources(pdschIndices, rxGrid, estChannelGridPorts);
            [pdschEq, csi] = nrEqualizeMMSE(pdschRx, pdschHest, noiseEst);

            [dlschLLRs, rxSymbols] = nrPDSCHDecode(carrier, pdsch, pdschEq, noiseEst);
            csi = nrLayerDemap(csi);
            Qm = length(dlschLLRs{1}) / length(rxSymbols{1});
            csi1 = repmat(csi{1}.', Qm, 1);
            dlschLLRs{1} = dlschLLRs{1} .* csi1(:);

            decodeDLSCH.TransportBlockLength = trBlkSize;
            [~, blkerr] = decodeDLSCH(dlschLLRs, pdsch.Modulation, pdsch.NumLayers, ...
                harqEntity.RedundancyVersion, harqEntity.HARQProcessID);

            % Bookkeeping: delivered / lost / latency (Eq. 1)
            txCount(pid) = txCount(pid) + 1;
            if ~blkerr
                nDelivered     = nDelivered + 1;
                sumTxDelivered = sumTxDelivered + txCount(pid);
                sumLatencyMs(snrIdx) = sumLatencyMs(snrIdx) + ...
                    (nslot - txStartSlot(pid) + 1) * slotDurationMs;
                txCount(pid) = 0;
                txStartSlot(pid) = NaN;
            elseif txCount(pid) == Q2_NTX            % all attempts used: lost
                nLost = nLost + 1;
                txCount(pid) = 0;
                txStartSlot(pid) = NaN;
            end

            simThroughput(snrIdx) = simThroughput(snrIdx) + ~blkerr * trBlkSize;
            maxThroughput(snrIdx) = maxThroughput(snrIdx) + trBlkSize;

            updateAndAdvance(harqEntity, blkerr, trBlkSize, pdschIndicesInfo.G);
            newWtx = hSVDPrecoders(carrier, pdsch, estChannelGridAnts, pdschextra.PRGBundleSize);
        end

        nDeliveredAll(snrIdx) = nDelivered;
        residualBLER(snrIdx)  = nLost / max(nDelivered + nLost, 1);
        if nDelivered > 0
            avgTx(snrIdx) = sumTxDelivered / nDelivered;
        end
    end

    % Results for this modulation
    lat = sumLatencyMs ./ max(nDeliveredAll, 1);
    lat(nDeliveredAll == 0) = NaN;               % no delivered blocks: undefined
    thrMbps = 1e-6 * simThroughput / (simParameters.NFrames * 10e-3);

    latencyAll(:,mIdx)    = lat;
    throughputAll(:,mIdx) = thrMbps;
    throughputPct(:,mIdx) = 100 * simThroughput ./ maxThroughput;
    residualAll(:,mIdx)   = residualBLER;
    avgTxAll(:,mIdx)      = avgTx;

    plot(axLat, simParameters.SNRIn, lat,     "o-", "DisplayName", modulation, "LineWidth", 1.5);
    plot(axThr, simParameters.SNRIn, thrMbps, "o-", "DisplayName", modulation, "LineWidth", 1.5);
end

%% Plots and data
titleStr = sprintf("Q2 %s (%s), 1x1, N_{tx} = %d", Q2_ENV, simParameters.DelayProfile, Q2_NTX);
hold(axLat,"off"); xlabel(axLat,"SNR (dB)"); ylabel(axLat,"Mean latency (ms)");
grid(axLat,"on"); title(axLat,titleStr); legend(axLat,"Location","best");
hold(axThr,"off"); xlabel(axThr,"SNR (dB)"); ylabel(axThr,"Throughput (Mbit/s)");
grid(axThr,"on"); title(axThr,titleStr); legend(axThr,"Location","best");

if ~exist("Q2img","dir"),  mkdir("Q2img");  end
if ~exist("Q2data","dir"), mkdir("Q2data"); end
exportgraphics(figLat, sprintf("Q2img/latency_%s_ntx%d.png",    Q2_ENV, Q2_NTX), "Resolution", 300);
exportgraphics(figThr, sprintf("Q2img/throughput_%s_ntx%d.png", Q2_ENV, Q2_NTX), "Resolution", 300);

snr = simParameters.SNRIn(:);
T = array2table([snr latencyAll throughputAll throughputPct residualAll avgTxAll], ...
    "VariableNames", ["SNRdB" "Latency_ms_"+modulationlist "Thr_Mbps_"+modulationlist ...
    "Thr_pct_"+modulationlist "ResBLER_"+modulationlist "AvgTx_"+modulationlist]);
writetable(T, sprintf("Q2data/Q2_%s_ntx%d.csv", Q2_ENV, Q2_NTX));

%% Local functions
function estChannelGrid = getInitialChannelEstimate(carrier, propchannel, dataType, maxChDelay)
    ofdmInfo = nrOFDMInfo(carrier);
    chClone = propchannel.clone();
    chClone.release();
    chClone.ChannelFiltering = false;
    chClone.OutputDataType = dataType;
    chClone.NumTimeSamples = (ofdmInfo.SampleRate/1000/carrier.SlotsPerSubframe) + maxChDelay;
    estChannelGrid = chClone(carrier);
end

function estChannelGrid = precodeChannelEstimate(carrier, estChannelGrid, W)
    [K, L, R, P] = size(estChannelGrid);
    estChannelGrid = reshape(estChannelGrid, [K*L R P]);
    estChannelGrid = nrPDSCHPrecode(carrier, estChannelGrid, reshape(1:numel(estChannelGrid), [K*L R P]), W);
    estChannelGrid = reshape(estChannelGrid, K, L, R, []);
end

function [channel, simParameters] = createChannel(simParameters, waveformInfo)
    channel = nrTDLChannel;
    channel.PathGainSampleRate  = "auto";
    channel.NumTransmitAntennas = simParameters.NTxAnts;
    channel.NumReceiveAntennas  = simParameters.NRxAnts;
    channel.DelayProfile        = simParameters.DelayProfile;
    channel.DelaySpread         = simParameters.DelaySpread;
    channel.MaximumDopplerShift = simParameters.MaximumDopplerShift;
    channel.SampleRate          = waveformInfo.SampleRate;
    channel.ChannelResponseOutput = "ofdm-response";
end
