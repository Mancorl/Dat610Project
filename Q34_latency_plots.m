% Q34_latency_plots.m - mean latency per delivered block for Q3 and Q4
% Latency = time from the FIRST transmission of a block until it is decoded
% correctly. The 16 HARQ processes take turns, so a retransmission of the
% same block comes 16 slots later. A block needing k transmissions therefore
% has latency (16*(k-1) + 1) slots x 0.5 ms = 0.5 / 8.5 / 16.5 / 24.5 ms.
% Averaging over delivered blocks gives: (16*(avgTx-1) + 1) * 0.5 ms.

clear; close all
slotMs = 0.5;                  % slot duration at 30 kHz SCS (ms)
nProc  = 16;                   % number of HARQ processes = slots between retransmissions
lat = @(avgTx) (nProc*(avgTx - 1) + 1) * slotMs;   % mean latency (ms)
cols = lines(3);
scenList = ["urban" "rural"];

%% Q3: latency vs SNR for 4 / 12 / 25 LDPC iterations (HARQ on)
iterList = [4 12 25];
figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
for s = 1:numel(scenList)
    for i = 1:numel(iterList)
        d = load(sprintf("Results_Q3/Q3_%s_it%d_harq1.mat", scenList(s), iterList(i)));
        if scenList(s) == "urban", lineSt = "-"; else, lineSt = "--"; end
        plot(d.simParameters.SNRIn, lat(d.avgTx), "LineStyle", lineSt, "Marker", "o", ...
            "Color", cols(i,:), "LineWidth", 1.5, ...
            "DisplayName", sprintf("%s, %d iterations", scenList(s), iterList(i)));
    end
end
grid on; box on
xlabel("SNR (dB)"); ylabel("Mean latency (ms)");
xlim([0 16]); xticks(0:2:16); ylim([0 25]);
legend("Location","northeast"); set(gca,"FontSize",12);
exportgraphics(gcf, "Figures_Q3/Q3_latency.png", "Resolution",300, "BackgroundColor","white");

%% Q4: latency vs SNR for 3 / 60 / 120 km/h (HARQ on)
speedList = [3 60 120];
figure("Color","w", "WindowStyle","normal", "Position",[100 100 700 450]); hold on
for s = 1:numel(scenList)
    for v = 1:numel(speedList)
        d = load(sprintf("Results_Q4/Q4_%s_v%d_harq1.mat", scenList(s), speedList(v)));
        if scenList(s) == "urban", lineSt = "-"; else, lineSt = "--"; end
        plot(d.simParameters.SNRIn, lat(d.avgTx), "LineStyle", lineSt, "Marker", "o", ...
            "Color", cols(v,:), "LineWidth", 1.5, ...
            "DisplayName", sprintf("%s, %d km/h", scenList(s), speedList(v)));
    end
end
grid on; box on
xlabel("SNR (dB)"); ylabel("Mean latency (ms)");
xlim([0 16]); xticks(0:2:16); ylim([0 25]);
legend("Location","northeast"); set(gca,"FontSize",12);
exportgraphics(gcf, "Figures_Q4/Q4_latency.png", "Resolution",300, "BackgroundColor","white");

%% Print the latency values (ms), so they can be quoted in the report
fprintf("\nQ3 mean latency (ms), SNR 0:2:16 dB, HARQ on\n");
for s = 1:numel(scenList)
    for i = 1:numel(iterList)
        d = load(sprintf("Results_Q3/Q3_%s_it%d_harq1.mat", scenList(s), iterList(i)));
        fprintf("%-5s it=%2d: %s\n", scenList(s), iterList(i), sprintf("%6.1f", lat(d.avgTx)));
    end
end
fprintf("\nQ4 mean latency (ms), SNR 0:2:16 dB, HARQ on\n");
for s = 1:numel(scenList)
    for v = 1:numel(speedList)
        d = load(sprintf("Results_Q4/Q4_%s_v%d_harq1.mat", scenList(s), speedList(v)));
        fprintf("%-5s v=%3d: %s\n", scenList(s), speedList(v), sprintf("%6.1f", lat(d.avgTx)));
    end
end
disp("Saved Figures_Q3/Q3_latency.png and Figures_Q4/Q4_latency.png");