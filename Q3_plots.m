% Q3_plots.m - figures for Q3: can HARQ compensate for fewer LDPC iterations?
% Reads the saved results in Results_Q3 and makes report-ready figures.

clear; close all
iterList = [4 12 25];
harqList = [false true];
scenList = ["urban" "rural"];
cols = lines(3);                          % one colour per iteration count
outDir = "Figures_Q3";
if ~exist(outDir,"dir"), mkdir(outDir); end

%% Figure 1 and 2: throughput vs SNR (one figure per scenario)
for s = 1:numel(scenList)
    figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
    for i = 1:numel(iterList)
        for h = 1:numel(harqList)
            d = load(sprintf("Results_Q3/Q3_%s_it%d_harq%d.mat", scenList(s), iterList(i), harqList(h)));
            snr = d.simParameters.SNRIn;
            tputMbps = 1e-6 * d.simThroughput / (d.simParameters.NFrames * 10e-3);
            if harqList(h)
                lineSt = "-";  mk = "o"; lbl = "HARQ on";
            else
                lineSt = "--"; mk = "s"; lbl = "HARQ off";
            end
            plot(snr, tputMbps, "LineStyle", lineSt, "Marker", mk, "Color", cols(i,:), ...
                "LineWidth", 1.5, "DisplayName", sprintf("%d iterations, %s", iterList(i), lbl));
        end
    end
    grid on; box on
    xlabel("SNR (dB)"); ylabel("Throughput (Mbit/s)");
    ylim([0 32]); xlim([0 16]); xticks(0:2:16);   % same axes on all throughput figures
    legend("Location","southeast"); set(gca,"FontSize",12);
    exportgraphics(gcf, outDir + "/Q3_throughput_" + scenList(s) + ".png", ...
        "Resolution",300, "BackgroundColor","white");
end

%% Figure 3: average transmissions per delivered block (HARQ on only)
figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
for s = 1:numel(scenList)
    for i = 1:numel(iterList)
        d = load(sprintf("Results_Q3/Q3_%s_it%d_harq1.mat", scenList(s), iterList(i)));
        if scenList(s) == "urban", lineSt = "-"; else, lineSt = "--"; end
        plot(d.simParameters.SNRIn, d.avgTx, "LineStyle", lineSt, "Marker", "o", ...
            "Color", cols(i,:), "LineWidth", 1.5, ...
            "DisplayName", sprintf("%s, %d iterations", scenList(s), iterList(i)));
    end
end
grid on; box on
xlabel("SNR (dB)"); ylabel("Avg. transmissions per block");
xlim([0 16]); xticks(0:2:16); ylim([1 4]);
legend("Location","northeast"); set(gca,"FontSize",12);
exportgraphics(gcf, outDir + "/Q3_avg_transmissions.png", ...
    "Resolution",300, "BackgroundColor","white");

%% Print a summary table of throughput (%) for all 12 runs
fprintf("\nThroughput (%%) per SNR point (0:2:16 dB)\n");
for s = 1:numel(scenList)
    for i = 1:numel(iterList)
        for h = 1:numel(harqList)
            d = load(sprintf("Results_Q3/Q3_%s_it%d_harq%d.mat", scenList(s), iterList(i), harqList(h)));
            tp = 100 * d.simThroughput ./ d.maxThroughput;
            fprintf("%-5s it=%2d harq=%d: %s\n", scenList(s), iterList(i), harqList(h), sprintf("%6.1f", tp));
        end
    end
end
disp("Figures saved in Figures_Q3.");