% Q34_paper_figures.m
% Re-exports the Q3/Q4 figures at their real size in the report
cd('/MATLAB Drive/Dat610Project')
if ~exist("Figures_paper","dir"), mkdir("Figures_paper"); end

% ---- Q3 throughput ----
close all
Q3_plots
paperfig(figure(1), "Figures_paper/Q3_throughput_urban.png", 3, 12, "northoutside", [])
paperfig(figure(2), "Figures_paper/Q3_throughput_rural.png", 3, 12, "northoutside", [])

% ---- Q4 throughput ----
close all
Q4_plots
paperfig(figure(1), "Figures_paper/Q4_throughput_urban.png", 3, 12, "northoutside", [])
paperfig(figure(2), "Figures_paper/Q4_throughput_rural.png", 3, 12, "northoutside", [])

% ---- Q3 + Q4 latency ----
close all
Q34_latency_plots
paperfig(figure(1), "Figures_paper/Q3_latency.png", 2, 20, "northeast", [0 36])
paperfig(figure(2), "Figures_paper/Q4_latency.png", 2, 14, "northeast", [0 36])

close all
disp("Done: 6 figures saved in Figures_paper/")


function paperfig(fig, fileName, nCols, tokLen, legLoc, yLim)
% 5.8 cm wide = 0.32\textwidth in the IEEE two-column template
set(fig, "Color", "w");
ax = findall(fig, "Type", "axes");
set(ax, "FontSize", 8, "LineWidth", 0.5, ...
    "XTick", 0:4:16, "XTickLabelRotation", 0);
set(findall(fig, "Type", "line"), "LineWidth", 1, "MarkerSize", 3);
if ~isempty(yLim)
    ylim(ax, yLim);              % extra room at the top for the legend
    set(ax, "YTick", 0:10:30);
end

% Short legend labels
lg = findall(fig, "Type", "legend");
s = string(lg.String);
s = replace(s, " iterations", " it.");
s = replace(s, ", HARQ ", ", ");
lg.String = s;
set(lg, "FontSize", 6, "Location", legLoc, ...
    "NumColumns", nCols, "Box", "off", "ItemTokenSize", [tokLen 6]);

% Same plot area in all figures
set(ax, "Position", [0.16 0.17 0.79 0.58]);

% Print at the exact paper size
set(fig, "PaperUnits", "centimeters", "PaperPosition", [0 0 5.8 5.2], ...
    "PaperSize", [5.8 5.2]);
print(fig, fileName, "-dpng", "-r300");
end