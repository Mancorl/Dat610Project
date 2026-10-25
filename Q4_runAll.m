% Q4_runAll.m - runs all Q4 combinations and saves the results
% Q4: How does UE speed affect reliability, and how much does HARQ help?

speedList = [3 60 120];          % UE speed (km/h): walking, city driving, highway
harqList  = [false true];        % HARQ off / on
scenList  = ["urban" "rural"];   % environments, same as Q3
fcHz   = 3.5e9;                  % carrier frequency (Hz), band n78
cLight = 3e8;                    % speed of light (m/s)

Q3_ITER = 12;                    % LDPC iterations fixed: example default, Q3 showed little gain above 12

if ~exist("Results_Q4","dir"), mkdir("Results_Q4"); end

for q4s = 1:numel(scenList)
    for q4v = 1:numel(speedList)
        for q4h = 1:numel(harqList)

            % Fill the "boxes" that Q4_speed.m reads
            Q3_SCEN    = scenList(q4s);
            Q3_HARQ    = harqList(q4h);
            Q4_SPEED   = speedList(q4v);
            Q4_DOPPLER = (Q4_SPEED/3.6) * fcHz / cLight;   % Doppler f_D = v * f_c / c  (km/h -> m/s: divide by 3.6)

            fileName = sprintf("Results_Q4/Q4_%s_v%d_harq%d.mat", Q3_SCEN, Q4_SPEED, Q3_HARQ);
            if isfile(fileName)
                fprintf("Skip (already done): %s\n", fileName);
                continue
            end

            fprintf("\n=== Q4 run: %s, %d km/h (%.0f Hz), HARQ = %d ===\n", Q3_SCEN, Q4_SPEED, Q4_DOPPLER, Q3_HARQ);
            Q4_speed;

            save(fileName, "summaryTable", "simThroughput", "maxThroughput", "simParameters", ...
                "residualBLER", "avgTx", "Q4_SPEED", "Q4_DOPPLER");
            close all
        end
    end
end
disp("All Q4 runs done.");