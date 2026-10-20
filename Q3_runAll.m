scenList = ["urban" "rural"];   % ["urban" "rural"]

for q3s = 1:numel(scenList)
    for q3i = 1:numel(iterList)
        for q3h = 1:numel(harqList)

            % Fill the three "boxes" that Q3_iterations.m reads
            Q3_SCEN = scenList(q3s);
            Q3_ITER = iterList(q3i);
            Q3_HARQ = harqList(q3h);
            fprintf("\n=== Run: %s, %d iterations, HARQ = %d ===\n", Q3_SCEN, Q3_ITER, Q3_HARQ);

            Q3_iterations;

            % e.g. Results_Q3/Q3_urban_it4_harq1.mat
            fileName = sprintf("Results_Q3/Q3_%s_it%d_harq%d.mat", Q3_SCEN, Q3_ITER, Q3_HARQ);
            save(fileName, "summaryTable", "simThroughput", "maxThroughput", "simParameters", "residualBLER", "avgTx");
            close all
        end
    end
end

disp("All Q3 runs done.");