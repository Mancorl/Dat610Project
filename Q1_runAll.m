% Q1: When does IR outperform Chase combining?
% Sweeps HARQ scheme (IR / Chase) x target code rate x environment, over an SNR range.

schemeList = ["IR" "Chase"];
rateList   = [0.2 0.4 0.6 0.8];    % target code rate (16QAM, 1 layer); 
scenList   = ["urban" "rural"];    % environments

NFRAMES = 100;                  
SNR     = -2:2:18;              
ITER    = 12;                   

resultsDir = fullfile(fileparts(mfilename("fullpath")), "Results_Q1");
if ~exist("Results_Q1","dir"), mkdir("Results_Q1"); end

for q1s = 1:numel(scenList)
    for q1r = 1:numel(rateList)
        for q1h = 1:numel(schemeList)

            % Fill the "boxes" that Q1_iterations.m reads
            Q1_SCEN   = scenList(q1s);
            Q1_RATE   = rateList(q1r);
            Q1_SCHEME = schemeList(q1h);

            fileName = fullfile(resultsDir, ...
            sprintf("Q1_%s_R%02d_%s.mat", Q1_SCEN, round(100*Q1_RATE), Q1_SCHEME));
              
            if isfile(fileName)
                fprintf("Skip (already done): %s\n", fileName);
                continue
            end

            fprintf("\n=== Q1 run: %s, code rate %.2f, %s ===\n", Q1_SCEN, Q1_RATE, Q1_SCHEME);
            Q1_iterations;
            
            avgTx = avgTxFinished;
            save(fileName, "summaryTable", "simThroughput", "maxThroughput", "simParameters", ...
                "residualBLER", "avgTx", "avgTxFinished", "blerAfterK", "Q1_RATE", "Q1_SCHEME");
            close all
        end
    end
end
disp("All Q1 runs done.");
