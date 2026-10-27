%% NR PDSCH Throughput 
% This reference simulation shows how to measure the physical downlink
% shared channel (PDSCH) throughput of a 5G New Radio (NR) link, as defined
% by the 3GPP NR standard. The example implements the PDSCH and downlink
% shared channel (DL-SCH). The transmitter model includes PDSCH
% demodulation reference signals (DM-RS) and PDSCH phase tracking reference
% signals (PT-RS). The example supports both clustered delay line (CDL) and
% tapped delay line (TDL) propagation channels. You can perform perfect or
% practical synchronization and channel estimation. To reduce the total
% simulation time, you can use Parallel Computing Toolbox(TM) to execute 
% the SNR points in the SNR loop in parallel and use a compatible
% graphics processing unit (GPU) device for data-intensive computation.

% Copyright 2017-2026 The MathWorks, Inc.

%% Introduction
% This example measures the PDSCH throughput of a 5G link, as defined by
% the 3GPP NR standards TS 38.211, TS 38.212, TS 38.213, and TS 38.214.
% 
% The example models these 5G NR features:
% 
% * DL-SCH transport channel coding
% * Multiple codewords, dependent on the number of layers
% * PDSCH, PDSCH DM-RS, and PDSCH PT-RS generation
% * Variable subcarrier spacing and frame numerologies (2^n * 15 kHz)
% * Normal and extended cyclic prefix
% * TDL and CDL propagation channel models
% 
% Other features of the simulation are:
% 
% * PDSCH subband precoding using SVD
% * CP-OFDM modulation
% * Slot wise and non slot wise PDSCH and DM-RS mapping
% * Perfect or practical synchronization and channel estimation
% * HARQ operation with 16 processes
% * The example uses a single bandwidth part across the whole carrier
% 
% The figure shows the implemented processing chain. For clarity, the 
% DM-RS and PT-RS generation are omitted.
% 
% <<../PDSCHLinkExampleProcessingChain.png>>
%
% For a more detailed explanation of the steps implemented in this example,
% see <docid:5g_gs#mw_b41487f2-4e53-412e-83ff-b77bd3984819 Model 5G NR
% Communication Links> and
% <docid:5g_gs#mw_5441cb0f-86ed-4038-8735-d0a50ea68f60 DL-SCH and PDSCH
% Transmit and Receive Processing Chain>.
%
% This example supports both wideband and subband precoding. The precoding
% matrix is determined using SVD by averaging the channel estimate across
% all PDSCH PRBs in the allocation (wideband case) or in the subband.
% 
% To reduce the total simulation time, you can use the Parallel Computing
% Toolbox to execute the SNR points of the SNR loop in parallel.

%% Simulation Length and SNR Points
% Set the length of the simulation in terms of the number of 10ms frames. A
% large number of NFrames should be used to produce meaningful throughput
% results. Set the SNR points to simulate. The SNR for each layer is
% defined per RE, and it includes the effect of signal and noise across all
% antennas. For an explanation of the SNR definition that this example
% uses, see <docid:5g_ug#mw_37cef3ca-2f4b-433d-8d68-117a881ca5fd SNR
% Definition used in Link Simulations>.

simParameters = struct();       % Clear simParameters variable to contain all key simulation parameters 
simParameters.NFrames = NFRAMES;   % Number of 10 ms frames (set by Q1_runAll.m)
simParameters.SNRIn = SNR;         % SNR range (dB) (set by Q1_runAll.m)

%% GPU Acceleration
% When your simulation runs on a very large data set, using a GPU can
% accelerate the overall simulation time by performing the data-intensive 
% part of the computation on the GPU. Use the |UseGPU| flag to control the 
% use of a GPU in the simulation. When set to |"off"|, the simulation runs 
% on the CPU. When set to |"on"|, the simulation uses a GPU (requires 
% Parallel Computing Toolbox(TM)). When set to |"auto"|, the simulation 
% automatically uses a GPU device if a compatible GPU device is available. 

simParameters.UseGPU = "off";

%% Channel Estimator Configuration
% The logical variable |PerfectChannelEstimator| controls channel
% estimation and synchronization behavior. When set to |true|, perfect
% channel estimation and synchronization is used. Otherwise, practical
% channel estimation and synchronization is used, based on the values of
% the received PDSCH DM-RS.

simParameters.PerfectChannelEstimator = true;

%% Simulation Diagnostics
% The variable |DisplaySimulationInformation| controls the display of
% simulation information such as the HARQ process ID used for each
% subframe. In case of CRC error, the value of the index to the RV sequence
% is also displayed.

simParameters.DisplaySimulationInformation = false;

%%
% The |DisplayDiagnostics| flag enables the plotting of the EVM per layer.
% This plot monitors the quality of the received signal after equalization.
% The EVM per layer figure shows:
%
% * The EVM per layer per slot, which shows the EVM evolving with time.
% * The EVM per layer per resource block, which shows the EVM in frequency.
%
% This figure evolves with the simulation and is updated with each slot. 
% Typically, low SNR or channel fades can result in decreased signal 
% quality (high EVM). The channel affects each layer differently,
% therefore, the EVM values may differ across layers.
%
% In some cases, some layers can have a much higher EVM than others. These
% low-quality layers can result in CRC errors. This behavior may be caused
% by low SNR or by using too many layers for the channel conditions. You
% can avoid this situation by a combination of higher SNR, lower number
% of layers, higher number of antennas, and more robust transmission 
% (lower modulation scheme and target code rate).

simParameters.DisplayDiagnostics = false;

%% Carrier and PDSCH Configuration
% Set the key parameters of the simulation. These include:
% 
% * The bandwidth in resource blocks (12 subcarriers per resource block).
% * Subcarrier spacing: 15, 30, 60, 120 (kHz)
% * Cyclic prefix length: normal or extended
% * Cell ID
% * Number of transmit and receive antennas
% 
% A substructure containing the DL-SCH and PDSCH parameters is also
% specified. This includes:
% 
% * Target code rate
% * Allocated resource blocks (PRBSet)
% * Modulation scheme: "QPSK", "16QAM", "64QAM", "256QAM"
% * Number of layers
% * PDSCH mapping type
% * DM-RS configuration parameters
% * PT-RS configuration parameters
% 
% Other simulation wide parameters are:
% 
% * Propagation channel model delay profile (TDL or CDL)

% Set waveform type and PDSCH numerology (SCS and CP type)
simParameters.Carrier = nrCarrierConfig;         % Carrier resource grid configuration
simParameters.Carrier.NSizeGrid = 51;            % Bandwidth in number of resource blocks (51 RBs at 30 kHz SCS for 20 MHz BW)
simParameters.Carrier.SubcarrierSpacing = 30;    % 15, 30, 60, 120 (kHz)
simParameters.Carrier.CyclicPrefix = "Normal";   % "Normal" or "Extended" (Extended CP is relevant for 60 kHz SCS only)
simParameters.Carrier.NCellID = 1;               % Cell identity

% PDSCH/DL-SCH parameters
simParameters.PDSCH = nrPDSCHConfig;      % This PDSCH definition is the basis for all PDSCH transmissions in the BLER simulation
simParameters.PDSCHExtension = struct();  % This structure is to hold additional simulation parameters for the DL-SCH and PDSCH

% Define PDSCH time-frequency resource allocation per slot to be full grid (single full grid BWP)
simParameters.PDSCH.PRBSet = 0:simParameters.Carrier.NSizeGrid-1;                 % PDSCH PRB allocation
simParameters.PDSCH.SymbolAllocation = [0,simParameters.Carrier.SymbolsPerSlot];  % Starting symbol and number of symbols of each PDSCH allocation
simParameters.PDSCH.MappingType = "A";     % PDSCH mapping type ("A"(slot-wise),"B"(non slot-wise))

% Scrambling identifiers
simParameters.PDSCH.NID = simParameters.Carrier.NCellID;
simParameters.PDSCH.RNTI = 1;

% PDSCH resource block mapping (TS 38.211 Section 7.3.1.6)
simParameters.PDSCH.VRBToPRBInterleaving = 0; % Disable interleaved resource mapping
simParameters.PDSCH.VRBBundleSize = 4;

% Define the number of transmission layers to be used
simParameters.PDSCH.NumLayers = 1;            % Number of PDSCH transmission layers

% Define codeword modulation and target coding rate
% The number of codewords is directly dependent on the number of layers so ensure that 
% layers are set first before getting the codeword number
modulation = "16QAM";
if simParameters.PDSCH.NumCodewords > 1                             % Multicodeword transmission (when number of layers being > 4)
    simParameters.PDSCH.Modulation = {modulation,modulation};             % "QPSK", "16QAM", "64QAM", "256QAM"
    simParameters.PDSCHExtension.TargetCodeRate = [Q1_RATE Q1_RATE];   % Q1: code rate set by Q1_runAll.m
else
    simParameters.PDSCH.Modulation = modulation;                       % "QPSK", "16QAM", "64QAM", "256QAM"
    simParameters.PDSCHExtension.TargetCodeRate = Q1_RATE;             % Q1: code rate set by Q1_runAll.m (used to calculate transport block sizes)
end

% DM-RS and antenna port configuration (TS 38.211 Section 7.4.1.1)
simParameters.PDSCH.DMRS.DMRSTypeAPosition = 2;      % Mapping type A only. First DM-RS symbol position (2,3)
simParameters.PDSCH.DMRS.DMRSLength = 1;             % Number of front-loaded DM-RS symbols (1(single symbol),2(double symbol))
simParameters.PDSCH.DMRS.DMRSAdditionalPosition = 2; % Additional DM-RS symbol positions (max range 0...3)
simParameters.PDSCH.DMRS.DMRSConfigurationType = 2;  % DM-RS configuration type (1,2)
simParameters.PDSCH.DMRS.NumCDMGroupsWithoutData = 1;% Number of CDM groups without data
simParameters.PDSCH.DMRS.NIDNSCID = 1;               % Scrambling identity (0...65535)
simParameters.PDSCH.DMRS.NSCID = 0;                  % Scrambling initialization (0,1)
simParameters.PDSCH.DMRS.DMRSPortSet = [];           % Use this to specify explicit DM-RS port numbers (TS 38.212 Section 7.3.1.2). Empty corresponds to the first NumLayers valid ports

% PT-RS configuration (TS 38.211 Section 7.4.1.2)
simParameters.PDSCH.EnablePTRS = 0;                  % Enable or disable PT-RS (1 or 0)
simParameters.PDSCH.PTRS.TimeDensity = 1;            % PT-RS time density (L_PT-RS) (1, 2, 4)
simParameters.PDSCH.PTRS.FrequencyDensity = 2;       % PT-RS frequency density (K_PT-RS) (2 or 4)
simParameters.PDSCH.PTRS.REOffset = "00";            % PT-RS resource element offset ("00", "01", "10", "11")
simParameters.PDSCH.PTRS.PTRSPortSet = [];           % PT-RS antenna port, subset of DM-RS port set. Empty corresponds to lower DM-RS port number

% Reserved PRB patterns, if required (for CORESETs, forward compatibility etc)
simParameters.PDSCH.ReservedPRB{1}.SymbolSet = [];   % Reserved PDSCH symbols
simParameters.PDSCH.ReservedPRB{1}.PRBSet = [];      % Reserved PDSCH PRBs
simParameters.PDSCH.ReservedPRB{1}.Period = [];      % Periodicity of reserved resources

% Additional simulation and DL-SCH related parameters
%
% PDSCH PRB bundling (TS 38.214 Section 5.1.2.3)
simParameters.PDSCHExtension.PRGBundleSize = [];     % 2, 4, or [] to signify "wideband"
%
% HARQ process and rate matching/TBS parameters
simParameters.PDSCHExtension.XOverhead = 6*simParameters.PDSCH.EnablePTRS; % Set PDSCH rate matching overhead for TBS (Xoh) to 6 when PT-RS is enabled, otherwise 0
simParameters.PDSCHExtension.NHARQProcesses = 16;    % Number of parallel HARQ processes to use
simParameters.PDSCHExtension.EnableHARQ = true;         % Q1: HARQ always on, the scheme (IR or Chase) is chosen by Q1_SCHEME
simParameters.PDSCHExtension.HARQScheme = Q1_SCHEME;    % "IR" or "Chase" (decides the RV sequence further down)
simParameters.PDSCHExtension.EnableCBGTransmission = false; % Enable CBG-based transmission, otherwise TB-based transmission
simParameters.PDSCHExtension.MaxNumCBG = 4;          % Maximum number of CBGs per transport block for each HARQ process in CBG-based transmission

% LDPC decoder parameters
% Available algorithms: "Belief propagation", "Layered belief propagation", "Normalized min-sum", "Offset min-sum"
simParameters.PDSCHExtension.LDPCDecodingAlgorithm = "Normalized min-sum";
simParameters.PDSCHExtension.MaximumLDPCIterationCount = ITER;   % fixed by Q1_runAll.m (12, as in Q4)

% Define the overall transmission antenna geometry at end-points
% If using a CDL propagation channel then the integer number of antenna elements is
% turned into an antenna panel configured when the channel model object is created
simParameters.NTxAnts = 1;                        % Number of PDSCH transmission antennas (1,2,4,8,16,32,64,128,256,512,1024) >= NumLayers
if simParameters.PDSCH.NumCodewords > 1           % Multi-codeword transmission
    simParameters.NRxAnts = 8;                    % Number of UE receive antennas (even number >= NumLayers)
else
    simParameters.NRxAnts = 1;                    % Number of UE receive antennas (1 or even number >= NumLayers)
end

% Define data type ("single" or "double") for resource grids and waveforms
simParameters.DataType = "single";

% Define the general CDL or TDL propagation channel parameters.
% If you later want to debug unexpected simulation results, set DelayProfile to
% "None" to disable channel impairments due to mobility, fading, multipath,
% delay, and antenna effects.

%Start the code for DelayProfile------
% Environment: urban (TDL-C, NLOS, long echoes) or rural (TDL-D, LOS, short echoes)
if Q1_SCEN == "rural"
    simParameters.DelayProfile = "TDL-D";
    simParameters.DelaySpread = 30e-9;
else
    simParameters.DelayProfile = "TDL-C";
    simParameters.DelaySpread = 300e-9;
end
simParameters.MaximumDopplerShift = 10;  % 3 km/h at 3.5 GHz, same in both


% Cross-check the PDSCH layering against the channel geometry 
validateNumLayers(simParameters);

%% 
% The simulation relies on various pieces of information about the baseband 
% waveform, such as sample rate.

waveformInfo = nrOFDMInfo(simParameters.Carrier); % Get information about the baseband waveform after OFDM modulation step

%% Propagation Channel Model Construction
% Create the channel model object for the simulation. The example supports both the CDL and TDL channel 
% models, as defined in TR 38.901.

[channel,simParameters] = createChannel(simParameters,waveformInfo);

%% 
% Get the maximum number of delayed samples by a channel multipath
% component. This is calculated from the channel path with the largest
% delay and the implementation delay of the channel filter. This is
% required later to flush the channel filter to obtain the received signal.

chInfo = info(channel);
maxChDelay = chInfo.MaximumChannelDelay;

%%
% Create a prototype of the transport block based on simParameters.UseGPU 
if simParameters.UseGPU == "on" || (simParameters.UseGPU == "auto" && canUseGPU)
    device = gpuDevice().Name;
    fprintf("\nUsing GPU device %s for computation\n",device);
    simParameters.Prototype = zeros(0,0,"gpuArray");
else
    simParameters.Prototype = zeros(0,0);
end

%% Processing Loop
% To determine the throughput at each SNR point, analyze the PDSCH data 
% per transmission instance using the following steps:
% 
% * _Update current HARQ process._ Check the transmission status for the
% given HARQ process to determine whether a retransmission is required. If
% that is not the case then generate new data.
% * _Resource grid generation._ Perform channel coding by calling the
% <docid:5g_ref#mw_sysobj_nrDLSCH nrDLSCH> System object. The object
% operates on the input transport block and keeps an internal copy of the
% transport block in case a retransmission is required. Modulate the coded
% bits on the PDSCH by using the <docid:5g_ref#mw_function_nrPDSCH nrPDSCH>
% function. Then apply precoding to the resulting signal.
% * _Waveform generation._ OFDM modulate the generated grid.
% * _Noisy channel modeling._ Pass the waveform through a CDL or TDL
% fading channel. Add AWGN. For an explanation of the SNR definition that
% this example uses, see
% <docid:5g_ug#mw_37cef3ca-2f4b-433d-8d68-117a881ca5fd SNR Definition Used
% in Link Simulations>.
% * _Perform synchronization and OFDM demodulation._ For perfect
% synchronization, reconstruct the channel impulse response to synchronize
% the received waveform. For practical synchronization, correlate the
% received waveform with the PDSCH DM-RS. Then OFDM demodulate the
% synchronized signal.
% * _Perform channel estimation._ For perfect channel estimation,
% reconstruct the channel impulse response and perform OFDM demodulation.
% For practical channel estimation, use the PDSCH DM-RS.
% * _Perform equalization and CPE compensation._ MMSE equalize the
% estimated channel. Estimate the common phase error (CPE) by using the
% PT-RS symbols, then correct the error in each OFDM symbol within the
% range of reference PT-RS OFDM symbols.
% * _Precoding matrix calculation._ Generate the precoding matrix W for the
% next transmission by using singular value decomposition (SVD).
% * _Decode the PDSCH._ To obtain an estimate of the received codewords,
% demodulate and descramble the recovered PDSCH symbols for all transmit
% and receive antenna pairs, along with a noise estimate, by using the
% <docid:5g_ref#mw_function_nrPDSCHDecode nrPDSCHDecode> function.
% * _Decode the downlink shared channel (DL-SCH) and update HARQ process
% with the block CRC error._ Pass the vector of decoded soft bits to the
% <docid:5g_ref#mw_sysobj_nrDLSCHDecoder nrDLSCHDecoder> System object. The
% object decodes the codeword and returns the block CRC error used to
% determine the throughput of the system.

% Array to store the maximum throughput for all SNR points
numSNRPoints = numel(simParameters.SNRIn);
maxThroughput = zeros(numSNRPoints,1); 
% Array to store the simulation throughput for all SNR points
simThroughput = zeros(numSNRPoints,1);
% Array to store measured SNR for all SNR points
rxAntennaSNR = zeros(numSNRPoints,1);
% --- Q1: desmetrics for comparing IR and Chase ---
avgTxFinished = zeros(numSNRPoints,1);  % average transmissions per finished block 
blerAfterK = zeros(numSNRPoints,4);     % column k = fraction of finished blocks still wrong after k transmissions
residualBLER = zeros(numSNRPoints,1); 

% Set up redundancy version (RV) sequence for all HARQ processes
if simParameters.PDSCHExtension.EnableHARQ
    if Q1_SCHEME == "Chase"
        % Chase combining: every (re)transmission sends the SAME coded bits
        % (RV=0). The decoder soft buffer adds the LLRs, which gives an SNR
        % gain but no new parity bits.
        rvSeq = [0 0 0 0];
    else
        % Incremental redundancy: each retransmission sends new parity bits.
        % In the final report of RAN WG1 meeting #91 (R1-1719301), it was
        % observed in R1-1717405 that if performance is the priority, [0 2 3 1]
        % should be used. If self-decodability is the priority, it should be
        % taken into account that the upper limit of the code rate at which
        % each RV is self-decodable is in the following order: 0>3>2>1
        rvSeq = [0 2 3 1];
    end
else
    % HARQ disabled - single transmission with RV=0, no retransmissions
    rvSeq = 0;
end

% Create DL-SCH encoder system object to perform transport channel encoding
encodeDLSCH = nrDLSCH;
encodeDLSCH.MultipleHARQProcesses = true;
encodeDLSCH.TargetCodeRate = simParameters.PDSCHExtension.TargetCodeRate;

decodeDLSCH = nrDLSCHDecoder;
decodeDLSCH.MultipleHARQProcesses = true;
decodeDLSCH.TargetCodeRate = simParameters.PDSCHExtension.TargetCodeRate;
decodeDLSCH.LDPCDecodingAlgorithm = simParameters.PDSCHExtension.LDPCDecodingAlgorithm;
decodeDLSCH.MaximumLDPCIterationCount = simParameters.PDSCHExtension.MaximumLDPCIterationCount;

for snrIdx = 1:numSNRPoints      % comment out for parallel computing
% parfor snrIdx = 1:numSNRPoints % uncomment for parallel computing
% To reduce the total simulation time, you can execute this loop in
% parallel by using the Parallel Computing Toolbox. Comment out the 'for'
% statement and uncomment the 'parfor' statement. If the Parallel Computing
% Toolbox is not installed, 'parfor' defaults to normal 'for' statement.
% Because parfor-loop iterations are executed in parallel in a
% nondeterministic order, the simulation information displayed for each SNR
% point can be intertwined. To switch off simulation information display,
% set the 'displaySimulationInformation' variable above to false

    % Reset the random number generator so that each SNR point will
    % experience the same noise realization
    rng("default");
    
    % Take full copies of the simulation-level parameter structures so that they are not 
    % PCT broadcast variables when using parfor 
    simLocal = simParameters;
    waveinfoLocal = waveformInfo;
    
    % Take copies of channel-level parameters to simplify subsequent parameter referencing 
    carrier = simLocal.Carrier;
    pdsch = simLocal.PDSCH;
    pdschextra = simLocal.PDSCHExtension;
    decodeDLSCHLocal = decodeDLSCH;  % Copy of the decoder handle to help PCT classification of variable
    decodeDLSCHLocal.reset();        % Reset decoder at the start of each SNR point

    % Prepare simulation for new SNR point
    SNRdB = simLocal.SNRIn(snrIdx);
    fprintf("\nSimulating transmission scheme 1 (%dx%d) and SCS=%dkHz with %s channel at %gdB SNR for %d 10ms frame(s)\n", ...
        simLocal.NTxAnts,simLocal.NRxAnts,carrier.SubcarrierSpacing, ...
        simLocal.DelayProfile,SNRdB,simLocal.NFrames);
    
    % Specify the fixed order in which we cycle through the HARQ process IDs
    harqSequence = 0:pdschextra.NHARQProcesses-1;

    % Initialize the state of all HARQ processes
    harqEntity = HARQEntity(harqSequence,rvSeq,pdsch.NumCodewords);

    % Reset counters for this SNR point ---
    txCount = zeros(pdschextra.NHARQProcesses,1);   % transmissions so far for the block in each HARQ process
    nDelivered = 0;        % blocks that passed the CRC
    nLost = 0;             % blocks that failed every allowed transmission
    sumTxDelivered = 0;    % total transmissions used by delivered blocks
    deliveredAt = zeros(1,numel(rvSeq));   % Q1: deliveredAt(j) = blocks that passed on transmission number j

    % Reset the channel so that each SNR point will experience the same
    % channel realization
    reset(channel);
    
    % Total number of slots in the simulation period
    NSlots = simLocal.NFrames * carrier.SlotsPerFrame;
    
    % Obtain a precoding matrix (wtx) to be used in the transmission of the
    % first transport block
    estChannelGridAnts = getInitialChannelEstimate(carrier,channel,simLocal.DataType,maxChDelay);
    newWtx = 1;
    
    % Timing offset, updated in every slot for perfect synchronization and
    % when the correlation is strong for practical synchronization
    offset = 0;

    % Noise power, normalized by the IFFT size used in OFDM modulation, as
    % the OFDM modulator applies this normalization to the transmitted
    % waveform. Also normalize by the number of receive antennas, as the
    % channel model applies this normalization to the received waveform by
    % default
    snrLin = 10^(SNRdB/10);
    N0 = 1/sqrt(simLocal.NRxAnts*waveinfoLocal.Nfft*snrLin);
    nVar = N0^2*waveinfoLocal.Nfft;

    % Initialize variables to store power measurements
    rxSigPower = zeros(NSlots,1);

    % Loop over the entire waveform length
    for nslot = 0:NSlots-1
        
        % Update the carrier slot numbers for new slot
        carrier.NSlot = nslot;
                
        % Calculate the transport block sizes for the transmission in the slot
        [pdschIndices,pdschIndicesInfo] = nrPDSCHIndices(carrier,pdsch);
        trBlkSizes = nrTBS(pdsch.Modulation,pdsch.NumLayers,numel(pdsch.PRBSet),pdschIndicesInfo.NREPerPRB,pdschextra.TargetCodeRate,pdschextra.XOverhead);

        % HARQ processing
        for cwIdx = 1:pdsch.NumCodewords
            % If new data for current process and codeword then create a new DL-SCH transport block
            if harqEntity.NewData(cwIdx)
                trBlk = randi([0 1],trBlkSizes(cwIdx),1,"like",simLocal.Prototype);
                setTransportBlock(encodeDLSCH,trBlk,cwIdx-1,harqEntity.HARQProcessID);
                % If new data because of previous RV sequence time out then flush decoder soft buffer explicitly
                if harqEntity.SequenceTimeout(cwIdx)
                    resetSoftBuffer(decodeDLSCHLocal,cwIdx-1,harqEntity.HARQProcessID);
                end
            end
        end

        % Encode the DL-SCH transport blocks
        codedTrBlocks = encodeDLSCH(pdsch.Modulation,pdsch.NumLayers, ...
            pdschIndicesInfo.G,harqEntity.RedundancyVersion, ...
            harqEntity.HARQProcessID);

        % Get precoding matrix (wtx) calculated in previous slot
        wtx = newWtx;
        
        % Create a resource grid for a slot
        pdschGrid = nrResourceGrid(carrier,simLocal.NTxAnts, ...
        'OutputDataType',simLocal.DataType);
        
        % PDSCH modulation and precoding
        pdschSymbols = nrPDSCH(carrier,pdsch,codedTrBlocks);
        pdschAntSymbols = pdschSymbols;
        pdschAntIndices = pdschIndices;
        
        % PDSCH mapping in grid associated with PDSCH transmission period
        pdschGrid(pdschAntIndices) = pdschAntSymbols;
        
        % PDSCH DM-RS precoding and mapping
        dmrsSymbols = nrPDSCHDMRS(carrier,pdsch);
        dmrsIndices = nrPDSCHDMRSIndices(carrier,pdsch);
        dmrsAntSymbols = dmrsSymbols;
        dmrsAntIndices = dmrsIndices;
        pdschGrid(dmrsAntIndices) = dmrsAntSymbols;

        % PDSCH PT-RS precoding and mapping
        ptrsSymbols = nrPDSCHPTRS(carrier,pdsch);
        ptrsIndices = nrPDSCHPTRSIndices(carrier,pdsch);
        ptrsAntSymbols = ptrsSymbols;
        ptrsAntIndices = ptrsIndices;
        pdschGrid(ptrsAntIndices) = ptrsAntSymbols;

        % OFDM modulation
        txWaveform = nrOFDMModulate(carrier,pdschGrid);

        % Pass data through channel model. Append zeros at the end of the
        % transmitted waveform to flush channel content. These zeros take
        % into account any delay introduced in the channel. This is a mix
        % of multipath delay and implementation delay. This value may 
        % change depending on the sampling rate, delay profile, and delay
        % spread. The channel model also returns the OFDM channel response
        % and timing offset for the specified carrier
        txWaveform = [txWaveform; zeros(maxChDelay,size(txWaveform,2))]; %#ok<AGROW>
        [rxWaveform,pathGains,sampleTimes] = channel(txWaveform);
        pathFilters = getPathFilters(channel);
        timingOffset = nrPerfectTimingEstimate(pathGains,pathFilters);

        % Measure the received signal power at each Rx antenna. Average the
        % power across Rx antennas and normalize by the number of allocated
        % resource elements (REs). NRE counts the occupied REs in the
        % transmitted OFDM resource grid. This measurement assumes that all
        % physical channels and signals in the resource grid have the same
        % average power per RE.
        rxPowerAnt = rms(rxWaveform).^2;        
        NRE = nnz(any(pdschGrid,3));
        rxSigPower(nslot+1) = mean(rxPowerAnt)/NRE;

        % Add AWGN to the received time domain waveform
        noise = N0*randn(size(rxWaveform),"like",rxWaveform);
        rxWaveform = rxWaveform + noise;

        if (simLocal.PerfectChannelEstimator)
            % For perfect synchronization, use the timing offset obtained
            % from the channel
            offset = timingOffset;
        else
            % Practical synchronization. Correlate the received waveform
            % with the PDSCH DM-RS to give timing offset estimate 't' and
            % correlation magnitude 'mag'. The function
            % hSkipWeakTimingOffset is used to update the receiver timing
            % offset. If the correlation peak in 'mag' is weak, the current
            % timing estimate 't' is ignored and the previous estimate
            % 'offset' is used
            [t,mag] = nrTimingEstimate(carrier,rxWaveform,dmrsIndices,dmrsSymbols); 
            offset = hSkipWeakTimingOffset(offset,t,mag);
            % Display a warning if the estimated timing offset exceeds the
            % maximum channel delay
            if offset > maxChDelay
                warning(['Estimated timing offset (%d) is greater than the maximum channel delay (%d).' ...
                    ' This will result in a decoding failure. This may be caused by low SNR,' ...
                    ' or not enough DM-RS symbols to synchronize successfully.'],offset,maxChDelay);
            end
        end
        rxWaveform = rxWaveform(1+offset:end,:);

        % Perform OFDM demodulation on the received data to recreate the
        % resource grid, including padding in the event that practical
        % synchronization results in an incomplete slot being demodulated
        rxGrid = nrOFDMDemodulate(carrier,rxWaveform);
        [K,L,R] = size(rxGrid);
        if (L < carrier.SymbolsPerSlot)
            rxGrid = cat(2,rxGrid,zeros(K,carrier.SymbolsPerSlot-L,R));
        end

        if (simLocal.PerfectChannelEstimator)
            % For perfect channel estimate, use the OFDM channel response
            % obtained from the channel
            estChannelGridAnts = nrPerfectChannelEstimate( ...
            carrier,pathGains,pathFilters,offset,sampleTimes);

            % Use the precalculated noise variance as the perfect noise
            % estimate
            noiseEst = nVar;

            % Apply precoding to channel estimate and get PDSCH resource 
            % elements from the received grid and channel estimate
            estChannelGridPorts = precodeChannelEstimate(carrier,estChannelGridAnts,permute(wtx,[2 1 3]));
            [pdschRx,pdschHest] = nrExtractResources(pdschIndices,rxGrid,estChannelGridPorts);
        else
            % Practical channel estimation between the received grid and
            % each transmission layer, using the PDSCH DM-RS for each
            % layer. This channel estimate includes the effect of
            % transmitter precoding
            [estChannelGridPorts,noiseEst] = nrChannelEstimate(carrier,rxGrid,dmrsIndices,dmrsSymbols,"PRGBundleSize",pdschextra.PRGBundleSize,"CDMLengths",pdsch.DMRS.CDMLengths); 

            % Average noise estimate across PRGs and layers
            noiseEst = mean(noiseEst,"all");

            % Get PDSCH resource elements from the received grid and
            % channel estimate
            [pdschRx,pdschHest] = nrExtractResources(pdschIndices,rxGrid,estChannelGridPorts);

            % Remove precoding from estChannelGridPorts to get channel
            % estimate w.r.t. antennas
            estChannelGridAnts = precodeChannelEstimate(carrier,estChannelGridPorts,conj(wtx));
        end

        % Equalization
        [pdschEq,csi] = nrEqualizeMMSE(pdschRx,pdschHest,noiseEst);

        % Common phase error (CPE) compensation
        if ~isempty(ptrsIndices)
            % Estimate CPE of OFDM symbols spanned by the first and
            % last PT-RS OFDM symbols, inclusive.
            [ptrsRx,ptrsHest] = nrExtractResources(ptrsIndices,rxGrid,estChannelGridPorts);
            ptrsEq = nrEqualizeMMSE(ptrsRx,ptrsHest,noiseEst);
            ptrsPorts = ceil(max(([1;double(ptrsIndices(:))]))/(carrier.NSizeGrid*12*carrier.SymbolsPerSlot));
            cpe = nrPhaseNoiseEstimate(carrier,ptrsEq(:,ptrsPorts),ptrsIndices,ptrsSymbols);
            % Compensate CPE
            pdschEq = nrPhaseNoiseCompensate(carrier,pdschEq,pdschIndices,cpe);
        end

        % Decode PDSCH physical channel
        [dlschLLRs,rxSymbols] = nrPDSCHDecode(carrier,pdsch,pdschEq,noiseEst);
        
        % Display EVM per layer, per slot and per RB
        if (simLocal.DisplayDiagnostics)
            plotLayerEVM(NSlots,nslot,pdsch,size(pdschGrid),pdschIndices,pdschSymbols,pdschEq);
        end
        
        % Scale LLRs by CSI
        csi = nrLayerDemap(csi); % CSI layer demapping
        for cwIdx = 1:pdsch.NumCodewords
            Qm = length(dlschLLRs{cwIdx})/length(rxSymbols{cwIdx}); % bits per symbol
            csi{cwIdx} = repmat(csi{cwIdx}.',Qm,1);                 % expand by each bit per symbol
            dlschLLRs{cwIdx} = dlschLLRs{cwIdx} .* csi{cwIdx}(:);   % scale by CSI
        end
        
        % Decode the DL-SCH transport channel
        decodeDLSCHLocal.TransportBlockLength = trBlkSizes;
        [decbits,blkerr] = decodeDLSCHLocal(dlschLLRs, ...
            pdsch.Modulation,pdsch.NumLayers,harqEntity.RedundancyVersion, ...
            harqEntity.HARQProcessID);
        % --- Q3: count transmissions for the block in this HARQ process ---
        pid = harqEntity.HARQProcessID + 1;          % process number 0-15 -> index 1-16
        txCount(pid) = txCount(pid) + 1;             % one more transmission of this block
        if ~blkerr(1)
            % CRC passed: block delivered, record how many tries it needed
            nDelivered = nDelivered + 1;
            sumTxDelivered = sumTxDelivered + txCount(pid);
            deliveredAt(txCount(pid)) = deliveredAt(txCount(pid)) + 1;   % Q1: histogram of tries needed
            txCount(pid) = 0;                        % next block in this process starts from zero
        elseif txCount(pid) == numel(rvSeq)
            % CRC failed on the last allowed try: block is lost for good
            nLost = nLost + 1;
            txCount(pid) = 0;
        end

        % Store values to calculate throughput
        simThroughput(snrIdx) = simThroughput(snrIdx) + sum(~blkerr .* trBlkSizes);
        maxThroughput(snrIdx) = maxThroughput(snrIdx) + sum(trBlkSizes);

        % Update current process with CRC error and advance to next process
        procstatus = updateAndAdvance(harqEntity,blkerr,trBlkSizes,pdschIndicesInfo.G);
        if (simLocal.DisplaySimulationInformation)
            fprintf("\n(%3.2f%%) NSlot=%d, %s",100*(nslot+1)/NSlots,nslot,procstatus);
        end

        % Get precoding matrix for next slot
        newWtx = 1;

    end

    % Calculate the noise power per RE and Rx antenna. This is constant
    % across all slots.
    noisePower = N0^2/(waveinfoLocal.Nfft*carrier.SymbolsPerSlot);

    % Since the received power varies over time due to channel effects,
    % compute the average power across all slots to determine the average
    % SNR per receive antenna and RE.
    rxAntennaSNR(snrIdx) = pow2db(mean(rxSigPower)./noisePower);

    % Display the results dynamically in the command window
    if (simLocal.DisplaySimulationInformation)
        fprintf("\n");
    end
    fprintf("\nThroughput(Mbps) for %d frame(s) = %.4f\n",simLocal.NFrames,1e-6*simThroughput(snrIdx)/(simLocal.NFrames*10e-3));
    fprintf("Throughput(%%) for %d frame(s) = %.4f\n",simLocal.NFrames,simThroughput(snrIdx)*100/maxThroughput(snrIdx));
     
    % --- Q3: residual BLER and average transmissions for this SNR point ---
    % Guarded against 0/0 (no finished block, or no delivered block at low SNR)
    nFinished = nDelivered + nLost;
    if nFinished > 0
        residualBLER(snrIdx) = nLost / nFinished;
        avgTxFinished(snrIdx) = (sumTxDelivered + nLost*numel(rvSeq)) / nFinished;
        % BLER after k transmissions = lost blocks + blocks that needed more than k tries
        for k = 1:numel(rvSeq)
            blerAfterK(snrIdx,k) = (nLost + sum(deliveredAt(k+1:end))) / nFinished;
        end
    else
        residualBLER(snrIdx) = NaN;
        avgTxFinished(snrIdx) = NaN;
        blerAfterK(snrIdx,:) = NaN;
    end
    fprintf("[%s, R=%.2f] first-tx BLER = %.3f, residual BLER = %.3f, avg tx per finished block = %.2f\n", ...
        Q1_SCHEME, Q1_RATE, blerAfterK(snrIdx,1), residualBLER(snrIdx), avgTxFinished(snrIdx));
end

%% Results
% Display the measured throughput. This is calculated as the percentage of
% the maximum possible throughput of the link given the available resources
% for data transmission.

figure;
plot(simParameters.SNRIn,simThroughput*100./maxThroughput,"o-.")
xlabel("SNR (dB)"); ylabel("Throughput (%)"); grid on;
title(sprintf("%s (%dx%d) / NRB=%d / SCS=%dkHz", ...
              simParameters.DelayProfile,simParameters.NTxAnts,simParameters.NRxAnts, ...
              simParameters.Carrier.NSizeGrid,simParameters.Carrier.SubcarrierSpacing));

% Bundle key parameters and results into a combined structure for recording
simResults = struct();
simResults.simParameters = simParameters;
simResults.simThroughput = simThroughput;
simResults.maxThroughput = maxThroughput;
simResults.rxAntennaSNR = rxAntennaSNR;

summaryTable = processResults(simResults);

%%
% Display a table that contains the measured throughput and SNR. The SNRIn
% column refers to the target average SNR specified in the simulation. The
% Rx Antenna SNR column refers to the average SNR per receive antenna and
% RE measured at the output of the channel. The measured SNR includes
% effects caused by the channel and MIMO precoding. For an explanation of
% the SNR definition that this example uses, see
% <docid:5g_ug#mw_37cef3ca-2f4b-433d-8d68-117a881ca5fd SNR Definition Used
% in Link Simulations>.

disp(summaryTable);

%%
% The figure below shows throughput results obtained simulating 10000
% subframes (|NFrames = 1000|, |SNRIn = -18:2:16|).
%
% <<../longRunThroughput.png>>
%

%% References
% [1] 3GPP TS 38.211. "NR; Physical channels and modulation."
% _3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network_.
%
% [2] 3GPP TS 38.212. "NR; Multiplexing and channel coding." 
% _3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network_.
%
% [3] 3GPP TS 38.213. "NR; Physical layer procedures for control." 
% _3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network_.
%
% [4] 3GPP TS 38.214. "NR; Physical layer procedures for data."
% _3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network_.
%
% [5] 3GPP TR 38.901. "Study on channel model for frequencies from 0.5 to 100
% GHz."
% _3rd Generation Partnership Project; Technical Specification Group Radio
% Access Network_.

%% Local Functions

function summaryTable = processResults(results)
% Create a simulation results table

    NFrames = results.simParameters.NFrames;
    SNRIn = results.simParameters.SNRIn;
   
    totalBits = results.maxThroughput;
    correctBits = results.simThroughput;
    
    throughputMbps = round(1e-6*correctBits/(NFrames*10e-3),2);
    throughput = round(100*(correctBits./totalBits),2);
    
    bler = 100 - throughput;
    SNRout = round(results.rxAntennaSNR,1);
    summaryTable = table(SNRIn.',throughput,throughputMbps,bler,SNRout);

    summaryTable.Properties.VariableNames = ["SNRIn" "Throughput (%)" "Throughput (Mbps)" "BLER (%)" "Rx Antenna SNR"];

end

function validateNumLayers(simParameters)
% Validate the number of layers, relative to the antenna geometry

    numlayers = simParameters.PDSCH.NumLayers;
    ntxants = simParameters.NTxAnts;
    nrxants = simParameters.NRxAnts;
    antennaDescription = sprintf("min(NTxAnts,NRxAnts) = min(%d,%d) = %d",ntxants,nrxants,min(ntxants,nrxants));
    if numlayers > min(ntxants,nrxants)
        error("The number of layers (%d) must satisfy NumLayers <= %s", ...
            numlayers,antennaDescription);
    end
    
    % Display a warning if the maximum possible rank of the channel equals
    % the number of layers
    if (numlayers > 2) && (numlayers == min(ntxants,nrxants))
        warning(['The maximum possible rank of the channel, given by %s, is equal to NumLayers (%d).' ...
            ' This may result in a decoding failure under some channel conditions.' ...
            ' Try decreasing the number of layers or increasing the channel rank' ...
            ' (use more transmit or receive antennas).'],antennaDescription,numlayers); %#ok<SPWRN>
    end

end

function estChannelGrid = getInitialChannelEstimate(carrier,propchannel,dataType,maxChDelay)
% Obtain channel estimate before first transmission. This can be used to
% obtain a precoding matrix for the first slot.

    ofdmInfo = nrOFDMInfo(carrier);

    % Clone of the channel
    chClone = propchannel.clone();
    chClone.release();

    % No filtering needed to get perfect channel estimate
    chClone.ChannelFiltering = false;
    chClone.OutputDataType = dataType;
    if ~strcmp(chClone.DelayProfile,"None")
        chClone.NumTimeSamples = (ofdmInfo.SampleRate/1000/carrier.SlotsPerSubframe)+maxChDelay;
    end

    % Get the perfect channel estimate
    [pathGains,sampleTimes] = chClone();
    pathFilters = getPathFilters(chClone);

    estChannelGrid = nrPerfectChannelEstimate( ...
    carrier,pathGains,pathFilters,0,sampleTimes);
    
end

function estChannelGrid = precodeChannelEstimate(carrier,estChannelGrid,W)
    % This helper intentionally supports only one receive antenna and one
    % transmit antenna; it does not perform general MIMO precoding.
    [~,~,R,P] = size(estChannelGrid);
    if R ~= 1 || P ~= 1 || size(W,1) ~= 1 || size(W,2) ~= 1
        error('This R2022b-compatible version supports only 1x1 identity precoding.');
    end
end

function plotLayerEVM(NSlots,nslot,pdsch,siz,pdschIndices,pdschSymbols,pdschEq)
% Plot EVM information

    persistent slotEVM;
    persistent rbEVM
    persistent evmPerSlot;
    
    if (nslot==0)
        slotEVM = comm.EVM;
        rbEVM = comm.EVM;
        evmPerSlot = NaN(NSlots,pdsch.NumLayers);
        figure;
    end
    evmPerSlot(nslot+1,:) = slotEVM(pdschSymbols,pdschEq);
    subplot(2,1,1);
    plot(0:(NSlots-1),evmPerSlot,"o-");
    xlabel("Slot number");
    ylabel("EVM (%)");
    legend("layer " + (1:pdsch.NumLayers),"Location","EastOutside");
    title("EVM per layer per slot");

    subplot(2,1,2);
    [k,~,p] = ind2sub(siz,pdschIndices);
    rbsubs = floor((k-1) / 12);
    NRB = siz(1) / 12;
    evmPerRB = NaN(NRB,pdsch.NumLayers);
    for nu = 1:pdsch.NumLayers
        for rb = unique(rbsubs).'
            this = (rbsubs==rb & p==nu);
            evmPerRB(rb+1,nu) = rbEVM(pdschSymbols(this),pdschEq(this));
        end
    end
    plot(0:(NRB-1),evmPerRB,"x-");
    xlabel("Resource block");
    ylabel("EVM (%)");
    legend("layer " + (1:pdsch.NumLayers),"Location","EastOutside");
    title(['EVM per layer per resource block, slot #' num2str(nslot)]);
    
    drawnow;
    
end

function [channel,simParameters] = createChannel(simParameters,waveformInfo)

    % Construct the CDL or TDL channel model object
    if contains(simParameters.DelayProfile,"CDL","IgnoreCase",true) || ...
            strcmpi(simParameters.DelayProfile,"None")
    
        channel = nrCDLChannel; % CDL channel object
        
        % Turn the number of antennas into antenna panel array layouts. If
        % NTxAnts is not one of (1,2,4,8,16,32,64,128,256,512,1024), its value
        % is rounded up to the nearest value in the set. If NRxAnts is not 1 or
        % even, its value is rounded up to the nearest even number.
        channel = hArrayGeometry(channel,simParameters.NTxAnts,simParameters.NRxAnts);
        simParameters.NTxAnts = prod(channel.TransmitAntennaArray.Size);
        simParameters.NRxAnts = prod(channel.ReceiveAntennaArray.Size);
    
    else
    
        channel = nrTDLChannel; % TDL channel object
        
        % Set the channel geometry
        channel.NumTransmitAntennas = simParameters.NTxAnts;
        channel.NumReceiveAntennas = simParameters.NRxAnts;
    
    end
    
    % Assign simulation channel parameters and waveform sample rate to the
    % object, and specify OFDM channel response as the channel response output
    % so that perfect channel estimation is calculated while filtering the
    % signal
    channel.DelayProfile = simParameters.DelayProfile;
    if ~strcmp(channel.DelayProfile,"None")
        channel.DelaySpread = simParameters.DelaySpread;
        channel.MaximumDopplerShift = simParameters.MaximumDopplerShift;
        channel.SampleRate = waveformInfo.SampleRate;
    end

end
