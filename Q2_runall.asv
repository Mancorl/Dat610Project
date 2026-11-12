ntxList = [1 2 4 8];
if ~exist("Results_Q2","dir"), mkdir("Results_Q2"); end

for n = 1:numel(ntxList)
    Q2_NTX = ntxList(n);
    Q2;
    save(sprintf("Results_Q2/Q2_ntx%d.mat", Q2_NTX), ...
        "modulationlist","latencyAll","throughputAll","throughputPct", ...
        "residualAll","avgTxAll","simParameters","Q2_NTX");
    close all
end