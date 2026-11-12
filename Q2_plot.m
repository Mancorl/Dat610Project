ntxList = [1 2 4 8];                       % samme som i Q2_runall
budget  = (16*(ntxList-1) + 1) * 0.5;      % ligning (1), ms
mods    = ["QPSK" "16QAM" "64QAM" "256QAM"];

% Last inn resultatene
R = cell(numel(ntxList),1);
for n = 1:numel(ntxList)
    R{n} = load(sprintf("Results_Q2/Q2_ntx%d.mat", ntxList(n)));
end
snr = R{1}.simParameters.SNRIn;
col = lines(numel(ntxList));

% Figur i IEEE-sidebredde (ca. 18 cm)
fig = figure('Units','centimeters','Position',[2 2 18 9.5],'Color','w');
t = tiledlayout(fig,2,numel(mods),'TileSpacing','compact','Padding','compact');

for m = 1:numel(mods)
    % --- Rad 1: residual BLER (log-skala) ---
    ax = nexttile(t, m); hold(ax,'on');
    for n = 1:numel(ntxList)
        b = R{n}.residualAll(:,m);
        b(b == 0) = NaN;                   % 0 kan ikke vises på log-skala
        plot(ax, snr, b, '-o', 'Color',col(n,:), 'LineWidth',1, 'MarkerSize',3, ...
            'DisplayName', sprintf('%d tx (\\leq %.1f ms)', ntxList(n), budget(n)));
    end
    set(ax,'YScale','log'); ylim(ax,[1e-4 1]); grid(ax,'on');
    title(ax, mods(m));
    if m == 1, ylabel(ax,'Residual BLER'); end

    % --- Rad 2: throughput ---
    ax2 = nexttile(t, m + numel(mods)); hold(ax2,'on');
    for n = 1:numel(ntxList)
        plot(ax2, snr, R{n}.throughputAll(:,m), '-o', 'Color',col(n,:), ...
            'LineWidth',1, 'MarkerSize',3);
    end
    grid(ax2,'on'); xlabel(ax2,'SNR (dB)');
    if m == 1, ylabel(ax2,'Throughput (Mbit/s)'); end
end

% Felles legend øverst
lg = legend(nexttile(t,1), 'Orientation','horizontal');
lg.Layout.Tile = 'north';

fontsize(fig, 8, 'points');                % samme størrelse som teksten i rapporten

if ~exist('Q2img','dir'), mkdir('Q2img'); end
exportgraphics(fig, 'Q2img/Q2_combined.pdf', 'ContentType','vector');
exportgraphics(fig, 'Q2img/Q2_combined.png', 'Resolution',300);