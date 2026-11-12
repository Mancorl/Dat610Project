ntxList = [1 2 4 8];
budget  = (16*(ntxList-1) + 1) * 0.5;          % Eq. (1), ms
mods    = ["QPSK" "16QAM" "64QAM" "256QAM"];

R = cell(numel(ntxList),1);
for n = 1:numel(ntxList)
    R{n} = load(sprintf("Results_Q2/Q2_ntx%d.mat", ntxList(n)));
end
if ~exist('Q2img','dir'), mkdir('Q2img'); end

makeFig(R, ntxList, budget, mods, "throughputAll", "Throughput (Mbit/s)", false, "Q2img/Q2_throughput.pdf");
makeFig(R, ntxList, budget, mods, "latencyAll",    "Mean latency (ms)",   false, "Q2img/Q2_latency.pdf");
% makeFig(R, ntxList, budget, mods, "residualAll", "Residual BLER", true, "Q2img/Q2_bler.pdf");

function makeFig(R, ntxList, budget, mods, field, ylab, logY, fname)
    snr = R{1}.simParameters.SNRIn;
    col = lines(numel(ntxList));

    fig = figure('Units','centimeters','Position',[2 2 8.8 8.8],'Color','w');
    t = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');

    for m = 1:numel(mods)
        ax = nexttile(t, m); hold(ax,'on');
        for n = 1:numel(ntxList)
            y = R{n}.(field)(:,m);
            if logY, y(y == 0) = NaN; end          % 0 cannot be shown on log scale
            plot(ax, snr, y, '-o', 'Color',col(n,:), 'LineWidth',1, 'MarkerSize',2.5, ...
                'DisplayName', sprintf('%d tx (\\leq%.1f ms)', ntxList(n), budget(n)));
        end
        if logY, set(ax,'YScale','log'); ylim(ax,[1e-4 1]); end
        grid(ax,'on'); title(ax, mods(m)); xlim(ax,[snr(1) snr(end)]);
    end
    xlabel(t,'SNR (dB)'); ylabel(t, ylab);

    lg = legend(nexttile(t,1), 'Orientation','horizontal','NumColumns',2);
    lg.Layout.Tile = 'north';

    fontsize(fig, 7, 'points');
    exportgraphics(fig, fname, 'ContentType','vector');
end