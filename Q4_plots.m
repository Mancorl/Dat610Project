% Q4_plots.m - figures for Q4: how does UE speed affect reliability, and how much does HARQ help?
% Reads the saved results in Results_Q4 and makes report-ready figures.

clear; close all
speedList = [3 60 120];
harqList  = [false true];
scenList  = ["urban" "rural"];
cols = lines(3);                          % one colour per speed
outDir = "Figures_Q4";
if ~exist(outDir,"dir"), mkdir(outDir); end

%% Figure 1 and 2: throughput vs SNR (one figure per scenario)
for s = 1:numel(scenList)
    figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
    for v = 1:numel(speedList)
        for h = 1:numel(harqList)
            d = load(sprintf("Results_Q4/Q4_%s_v%d_harq%d.mat", scenList(s), speedList(v), harqList(h)));
            snr = d.simParameters.SNRIn;
            tputMbps = 1e-6 * d.simThroughput / (d.simParameters.NFrames * 10e-3);
            if harqList(h)
                lineSt = "-";  mk = "o"; lbl = "HARQ on";
            else
                lineSt = "--"; mk = "s"; lbl = "HARQ off";
            end
            plot(snr, tputMbps, "LineStyle", lineSt, "Marker", mk, "Color", cols(v,:), ...
                "LineWidth", 1.5, "DisplayName", sprintf("%d km/h, %s", speedList(v), lbl));
        end
    end
    grid on; box on
    xlabel("SNR (dB)"); ylabel("Throughput (Mbit/s)");
    ylim([0 32]); xlim([0 16]); xticks(0:2:16);   % same axes on all throughput figures
    legend("Location","southeast"); set(gca,"FontSize",12);
    exportgraphics(gcf, outDir + "/Q4_throughput_" + scenList(s) + ".png", ...
        "Resolution",300, "BackgroundColor","white");
end

%% Figure 3: average transmissions per delivered block (HARQ on only)
figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
for s = 1:numel(scenList)
    for v = 1:numel(speedList)
        d = load(sprintf("Results_Q4/Q4_%s_v%d_harq1.mat", scenList(s), speedList(v)));
        if scenList(s) == "urban", lineSt = "-"; else, lineSt = "--"; end
        plot(d.simParameters.SNRIn, d.avgTx, "LineStyle", lineSt, "Marker", "o", ...
            "Color", cols(v,:), "LineWidth", 1.5, ...
            "DisplayName", sprintf("%s, %d km/h", scenList(s), speedList(v)));
    end
end
grid on; box on
xlabel("SNR (dB)"); ylabel("Avg. transmissions per block");
xlim([0 16]); xticks(0:2:16); ylim([1 4]);
legend("Location","northeast"); set(gca,"FontSize",12);
exportgraphics(gcf, outDir + "/Q4_avg_transmissions.png", ...
    "Resolution",300, "BackgroundColor","white");

%% Print summary tables: throughput (%) and residual BLER for all 12 runs
fprintf("\nThroughput (%%) per SNR point (0:2:16 dB)\n");
for s = 1:numel(scenList)
    for v = 1:numel(speedList)
        for h = 1:numel(harqList)
            d = load(sprintf("Results_Q4/Q4_%s_v%d_harq%d.mat", scenList(s), speedList(v), harqList(h)));
            tp = 100 * d.simThroughput ./ d.maxThroughput;
            fprintf("%-5s v=%3d harq=%d: %s\n", scenList(s), speedList(v), harqList(h), sprintf("%6.1f", tp));
        end
    end
end
fprintf("\nResidual BLER per SNR point (0:2:16 dB)\n");
for s = 1:numel(scenList)
    for v = 1:numel(speedList)
        for h = 1:numel(harqList)
            d = load(sprintf("Results_Q4/Q4_%s_v%d_harq%d.mat", scenList(s), speedList(v), harqList(h)));
            fprintf("%-5s v=%3d harq=%d: %s\n", scenList(s), speedList(v), harqList(h), sprintf("%6.3f", d.residualBLER));
        end
    end
end
disp("Figures saved in Figures_Q4.");