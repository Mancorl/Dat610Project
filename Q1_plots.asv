% Reads the saved results in Results_Q1 and creates figures

clear; close all
schemeList = ["IR" "Chase"];
rateList   = [0.2 0.4 0.6 0.8];
scenList   = ["urban" "rural"];
tableSNR   = [4 8 12 16];            % SNR points (dB) printed in the table
cols = lines(numel(rateList));      
outDir = "Figures_Q1";
if ~exist(outDir,"dir"), mkdir(outDir); end

% Load everything once
R = cell(numel(scenList),numel(rateList),numel(schemeList));
for s = 1:numel(scenList)
    for r = 1:numel(rateList)
        for h = 1:numel(schemeList)
            f = sprintf("Results_Q1/Q1_%s_R%02d_%s.mat", scenList(s), round(100*rateList(r)), schemeList(h));
            if isfile(f), R{s,r,h} = load(f); end
        end
    end
end

for s = 1:numel(scenList)

    %% Figure 1: throughput (%) vs SNR, one panel per code rate, IR vs Chase
    figure("Color","w","WindowStyle","normal","Position",[100 100 900 650]);
    for r = 1:numel(rateList)
        subplot(2,2,r); hold on
        for h = 1:numel(schemeList)
            d = R{s,r,h}; if isempty(d), continue; end
            tp = 100 * d.simThroughput ./ d.maxThroughput;
            if schemeList(h) == "IR", st = "-o"; else, st = "--s"; end
            plot(d.simParameters.SNRIn, tp, st, "LineWidth",1.5,"DisplayName",schemeList(h));
        end
        grid on; box on; ylim([0 100]);
        title(sprintf("R = %.1f",rateList(r))); xlabel("SNR (dB)"); ylabel("Throughput (%)");
        legend("Location","southeast"); set(gca,"FontSize",11);
    end
    sgtitle(sprintf("IR vs Chase, 16QAM, %s",scenList(s)));
    exportgraphics(gcf, outDir + "/Q1_throughput_" + scenList(s) + ".png","Resolution",300,"BackgroundColor","white");

    %% Figure 2: residual BLER vs SNR (log), one panel per code rate
    figure("Color","w","WindowStyle","normal","Position",[100 100 900 650]);
    for r = 1:numel(rateList)
        subplot(2,2,r); hold on
        for h = 1:numel(schemeList)
            d = R{s,r,h}; if isempty(d), continue; end
            b = d.residualBLER; b(b==0) = NaN;      
            if schemeList(h) == "IR", st = "-o"; else, st = "--s"; end
            semilogy(d.simParameters.SNRIn, b, st, "LineWidth",1.5,"DisplayName",schemeList(h));
        end
        set(gca,"YScale","log"); grid on; box on; ylim([1e-3 1]);
        title(sprintf("R = %.1f",rateList(r))); xlabel("SNR (dB)"); ylabel("Residual BLER (after 4 tx)");
        legend("Location","southwest"); set(gca,"FontSize",11);
    end
    sgtitle(sprintf("IR vs Chase, 16QAM, %s",scenList(s)));
    exportgraphics(gcf, outDir + "/Q1_residualBLER_" + scenList(s) + ".png","Resolution",300,"BackgroundColor","white");

    %% Figure 3: IR minus Chase throughput (percentage points) vs SNR, one line per code rate.
    % Positive = IR better
    figure("Color","w","WindowStyle","normal","Position",[100 100 700 450]); hold on
    for r = 1:numel(rateList)
        dI = R{s,r,1}; dC = R{s,r,2};
        if isempty(dI) || isempty(dC), continue; end
        delta = 100*dI.simThroughput./dI.maxThroughput - 100*dC.simThroughput./dC.maxThroughput;
        plot(dI.simParameters.SNRIn, delta, "-o","Color",cols(r,:),"LineWidth",1.5, ...
            "DisplayName",sprintf("R = %.1f",rateList(r)));
    end
    yline(0,"k:","HandleVisibility","off");
    grid on; box on; xlabel("SNR (dB)"); ylabel("Throughput IR - Chase (percentage points)");
    title(sprintf("%s: positive = IR better",scenList(s)));
    legend("Location","best"); set(gca,"FontSize",12);
    exportgraphics(gcf, outDir + "/Q1_delta_" + scenList(s) + ".png","Resolution",300,"BackgroundColor","white");
end

%% Table: IR vs Chase by code rate and SNR
rows = table();
for s = 1:numel(scenList)
    for r = 1:numel(rateList)
        dI = R{s,r,1}; dC = R{s,r,2};
        if isempty(dI) || isempty(dC), continue; end
        for snr = tableSNR
            i = find(dI.simParameters.SNRIn == snr, 1);
            if isempty(i), continue; end
            tpI = 100*dI.simThroughput(i)/dI.maxThroughput(i);
            tpC = 100*dC.simThroughput(i)/dC.maxThroughput(i);
            rows = [rows; table(scenList(s), rateList(r), snr, ...
                round(100*dI.blerAfterK(i,1),1), ...                       % first-tx BLER (%), same for both schemes
                round(100*dI.residualBLER(i),2), round(100*dC.residualBLER(i),2), ...
                round(dI.avgTxFinished(i),2), round(dC.avgTxFinished(i),2), ...
                round(tpI,1), round(tpC,1), round(tpI-tpC,1), ...
                'VariableNames',["Scenario" "Code rate" "SNR (dB)" "First-tx BLER (%)" ...
                "Resid. BLER IR (%)" "Resid. BLER Chase (%)" "Avg tx IR" "Avg tx Chase" ...
                "Tput IR (%)" "Tput Chase (%)" "IR - Chase (pp)"])]; %#ok<AGROW>
        end
    end
end
disp(rows);
if ~isempty(rows), writetable(rows, outDir + "/Q1_table.csv"); end

%% First-transmission BLER must be (almost) the same for IR and Chase
% both start with RV=0. 
fprintf("\nMax |first-tx BLER IR - Chase| per scenario/code rate (should be small, noise only):\n");
for s = 1:numel(scenList)
    for r = 1:numel(rateList)
        dI = R{s,r,1}; dC = R{s,r,2};
        if isempty(dI) || isempty(dC), continue; end
        fprintf("%-5s R=%.1f: %.3f\n", scenList(s), rateList(r), max(abs(dI.blerAfterK(:,1)-dC.blerAfterK(:,1)),[],"omitnan"));
    end
end
disp("Figures saved in Figures_Q1.");
