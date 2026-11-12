% Runs Q2 for every latency budget (Ntx) and both environments, using the
% same link as Q1/Q3/Q4 (Table I). 4 Ntx x 2 environments x 4 modulations.
ntxList = [1 2 4 8];
envList = ["urban" "rural"];
if ~exist("Results_Q2","dir"), mkdir("Results_Q2"); end

for e = 1:numel(envList)
    for n = 1:numel(ntxList)
        Q2_ENV = envList(e);
        Q2_NTX = ntxList(n);
        Q2;
        save(sprintf("Results_Q2/Q2_%s_ntx%d.mat", Q2_ENV, Q2_NTX), ...
            "modulationlist","latencyAll","throughputAll","throughputPct", ...
            "residualAll","avgTxAll","simParameters","Q2_NTX","Q2_ENV");
        close all
        clearvars -except ntxList envList e n
    end
end
