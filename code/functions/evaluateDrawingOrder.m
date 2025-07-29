function d = evaluateDrawingOrder(d, cfg)

% get drawing order
[d, cfg] = loadDrawingOrder(cfg, d);

% loop thorufh scene categories
for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    %% compare mean drawing order to mean fixation order
    drawMat = d.drawingOrder.(category).table;
    meanDraw  = mean(drawMat, 'omitnan');
    fixMat = d.GDM.(category).ObjectCatePrio;
    meanFix = mean(fixMat, 'omitnan');
    [rvals, pvals] = corr([meanDraw', meanFix'], 'type', 'Spearman','rows','pairwise');
    d.drawingOrder.(category).corr2fixationOrder_r = rvals(1,2);
    d.drawingOrder.(category).corr2fixationOrder_p = pvals(1,2);

    % plot
    figure;
    hold on
    scatter(meanDraw(~isnan(meanDraw)), meanFix(~isnan(meanDraw)), 60, 'filled');
    xlabel('Mean Drawing Order');
    ylabel('Mean Fixation Order');
    title(sprintf('Mean order correlation %s: r = %.2f, p = %.4f',...
        category, rvals(1,2), pvals(1,2)));
    h1 = lsline;
    h1.LineWidth = 3;
    scatter(meanDraw(~isnan(meanDraw)), meanFix(~isnan(meanDraw)), 60, 'filled');

    % label points (object names)
    text(meanDraw(~isnan(meanDraw)) + 0.2, meanFix(~isnan(meanDraw)),...
        cfg.(['categoriesNames_', category])(~isnan(meanDraw)), 'FontSize', 8);

    %% own vs other

    % init matrices
    ownCorrs = zeros(cfg.n,1);
    otherCorrs = zeros(cfg.n,1);

    for iSub = 1:cfg.n
        fixOwn = fixMat(iSub, :);
        drawOwn = drawMat(iSub, :);

        % Own correlation
        [rvals, ~] = corr([fixOwn', drawOwn'], 'type', 'Spearman','rows','pairwise');
        ownCorrs(iSub) = rvals(1,2);

        % Other correlations (exclude self)
        otherSubs = setdiff(1:cfg.n, iSub);
        tmpCorrs = zeros(length(otherSubs), 1);
        for iOther = 1:length(otherSubs)
            drawOther = drawMat(otherSubs(iOther), :);
            [rvals, ~] = corr([fixOwn', drawOther'], 'type', 'Spearman','rows','pairwise');
            tmpCorrs(iOther) = rvals(1,2);
        end
        otherCorrs(iSub) = mean(tmpCorrs, 'omitnan');
    end

    % store differences in table
    diffCorrs = ownCorrs - otherCorrs;
    d.drawingOrder.(category).ownVsOther = table((cfg.subNums)', ownCorrs, otherCorrs, diffCorrs, ...
        'VariableNames', {'Subject', 'OwnCorr', 'OtherCorr', 'Difference'});

%     % Optional: plot histogram of difference
%     figure;
%     histogram(diffCorrs, 'FaceColor', [0.2 0.6 1]);
%     xlabel('Own - Other Correlation');
%     ylabel('Number of Subjects');
%     title('Self vs Others Correlation Difference');

end 

% plot own vs other bar plots 
diffs = [d.drawingOrder.bathroom.ownVsOther.Difference, ....
    d.drawingOrder.kitchen.ownVsOther.Difference];

mean_data = mean(diffs, 1, 'omitnan');
sem_data = std(diffs, 0, 1, 'omitnan')/sqrt(cfg.n);

% stats including False Discovery Rate (FDR) correction
[~, pv] = ttest(diffs, 0, 'tail', 'right');
[~, ~, ~, adj_pv] = fdr_bh(pv);

% Create bar plot
figure;
hold on;

% Bar plot with error bars
bar_handle = bar(mean_data, 'FaceColor', 'flat');
errorbar(1:2, mean_data, sem_data, 'k', 'LineStyle', 'none', 'LineWidth', 1.5);

% Add jittered individual points
jitter_amount = 0.1; % Adjust jitter spread
for iBar = 1:2
    x_jitter = iBar + (rand(cfg.n, 1) - 0.5) * jitter_amount;
    scatter(x_jitter, diffs(:, iBar), 5, 'filled', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'b');

    % add asterisks
    text(iBar-0.1, max(diffs(:, iBar)) + 0.01, pval2asterisks(adj_pv(iBar)), 'FontSize', 15, 'FontWeight', 'bold')
end

% Customize plot
xticks(1:2);
xticklabels(cfg.categories);
xlabel('Scene category');
ylabel('Own correlation - mean other correlation');
title('Own vs other');

end