function d = evaluateDrawingOrder(d, cfg)

if ~isfield(cfg, 'regressOutSize'); cfg.regressOutSize = true; end
if ~isfield(cfg, 'partialCorr'); cfg.partialCorr = true; end

% get drawing order
[d, cfg] = loadDrawingOrder(cfg, d);

% loop thorufh scene categories
for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    % get mean size of object category in stimuli
    avgObjSize = getObjectSizes(category);

    % take drawing order
    drawMat = d.drawingOrder.(category).table;
    meanDraw  = mean(drawMat, 'omitnan');

    % take fixation order
    fixMat = d.GDM.(category).ObjectCatePrio;
    %     if cfg.regressOutSize
    %
    %        
    %
    %         % Residuals after regressing out object size
    %         fixMatRes = zeros(size(fixMat));
    %
    %         for iSub = 1:cfg.n
    %             y = fixMat(iSub, :)';           % fixation order for subject s (column vector)
    %             X = [ones(width(fixMat), 1), avgObjSize'];  % design matrix with intercept
    %
    %             % Linear regression: y = b0 + b1 * size + error
    %             b = X \ y;                   % Ordinary least squares
    %             y_hat = X * b;               % Predicted fixation order
    %             resid = y - y_hat;           % Residuals
    %
    %             fixMatRes(iSub, :) = resid';  % store residuals as row
    %         end
    %
    %         % overwrite old matrix
    %         fixMat = fixMatRes;
    %     end
    meanFix = mean(fixMat, 'omitnan');

    %% compare mean drawing order to mean fixation order             
    if cfg.partialCorr
        [rval, pval] = partialcorr(meanFix', meanDraw', avgObjSize', 'tail','right', 'type', 'Spearman','rows','pairwise');
    else
        [rvals, pvals] = corr([meanFix', meanDraw'], 'tail','right', 'type', 'Spearman','rows','pairwise');
        rval = rvals(1,2);
        pval = pvals(1,2);
    end

    d.drawingOrder.(category).corr2fixationOrder_r = rval;
    d.drawingOrder.(category).corr2fixationOrder_p = pval;

    % plot
    figure;
    hold on
    scatter(meanDraw(~isnan(meanDraw)), meanFix(~isnan(meanDraw)), 60, 'filled');
    xlabel('Mean Drawing Order');
    ylabel('Mean Fixation Order');
    title(sprintf('Mean order correlation %s: r = %.2f, p = %.4f',...
        category, rval, pval));
    h1 = lsline;
    h1.LineWidth = 3;
    scatter(meanDraw(~isnan(meanDraw)), meanFix(~isnan(meanDraw)), 60, tiedrank(1-avgObjSize(~isnan(meanDraw))),'filled');
    colormap(parula);
    cb = colorbar;
    cb.Label.String = 'Ranked Object Size';
    title(['Mean Fixation vs Mean Drawing Order (colored by Ranked Object Size) - ', category]);

    % add stats
    text(min(meanDraw(~isnan(meanDraw))) + 0.02, max(meanFix(~isnan(meanDraw))) - 0.02, ...
        sprintf('r = %.2f, p = %.3g', rval, pval), ...
        'FontSize', 12, 'VerticalAlignment', 'top');

    if cfg.partialCorr
        labelString = 'Partial correaltion';
    else
        labelString = 'Spearman Correaltion';
    end 
    text(min(meanDraw(~isnan(meanDraw))) + 0.02, max(meanFix(~isnan(meanDraw))) + 0.02, ...
        labelString, 'FontSize', 12, 'VerticalAlignment', 'top');

    % label points (object names)
    text(meanDraw(~isnan(meanDraw)) + 0.2, meanFix(~isnan(meanDraw)),...
        cfg.(['categoriesNames_', category])(~isnan(meanDraw)), 'FontSize', 8);

    %% linear mixed effect model

    % build long table
    longTable = table;
    subsMat = repmat(cfg.subNums', 1, width(fixMat));
    longTable.subject = reshape(subsMat, [], 1);
    longTable.fixOrder = reshape(fixMat, [], 1);
    longTable.drawingOrder = reshape(drawMat, [], 1);
    objSizeMat = repmat(avgObjSize, height(fixMat), 1);
    longTable.objectSize = reshape(objSizeMat, [], 1);
    longTable.sceneCategory = repmat(iCate, height(longTable), 1);

    % remove rows for not drawn objects
    longTable = longTable(~isnan(longTable.drawingOrder), :);

    % store long table in d
    d.drawingOrder.(category).table4lme = longTable;

    % process variables 
    longTable.subject = categorical(longTable.subject);
    longTable.fixOrder = zscore(longTable.fixOrder);
    longTable.drawingOrder = zscore(longTable.drawingOrder);
    longTable.objectSize = zscore(longTable.objectSize);

    % fit LME
    lme = fitlme(longTable, ...
    ['fixOrder ~ drawingOrder*objectSize +' ...
    ' (drawingOrder*objectSize|subject)']);
    disp(['R square adjusted for ', category, ': ', num2str(lme.Rsquared.Adjusted)])
    anovaResults.(category) = anova(lme);
    disp(anovaResults.(category))


   
    %% own vs other

    % init matrices
    ownCorrs = zeros(cfg.n,1);
    otherCorrs = zeros(cfg.n,1);

    for iSub = 1:cfg.n
        fixOwn = fixMat(iSub, :);
        drawOwn = drawMat(iSub, :);

        % Own correlation
        if cfg.partialCorr
            [rval, ~] = partialcorr(fixOwn', drawOwn', avgObjSize', 'tail','right', 'type', 'Spearman','rows','pairwise');
        else
            [rvals, ~] = corr([fixOwn', drawOwn'], 'tail','right', 'type', 'Spearman','rows','pairwise');
            rval = rvals(1,2);
        end
        ownCorrs(iSub) = rval;

        % Other correlations (exclude self)
        otherSubs = setdiff(1:cfg.n, iSub);
        tmpCorrs = zeros(length(otherSubs), 1);
        for iOther = 1:length(otherSubs)
            drawOther = drawMat(otherSubs(iOther), :);
            if cfg.partialCorr
                [rval, ~] = partialcorr(fixOwn', drawOther', avgObjSize', 'tail','right', 'type', 'Spearman','rows','pairwise');
            else
                [rvals, ~] = corr([fixOwn', drawOther'], 'tail','right', 'type', 'Spearman','rows','pairwise');
                rval = rvals(1,2);
            end
            tmpCorrs(iOther) = rval;
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

%% liner modelling for full experiment

superLongTable = [d.drawingOrder.bathroom.table4lme; d.drawingOrder.kitchen.table4lme];

% process variables
superLongTable.subject = categorical(superLongTable.subject);
superLongTable.fixOrder = zscore(superLongTable.fixOrder);
superLongTable.drawingOrder = zscore(superLongTable.drawingOrder);
superLongTable.objectSize = zscore(superLongTable.objectSize);
superLongTable.sceneCategory = categorical(superLongTable.sceneCategory);

% fit LME
lme_full = fitlme(superLongTable, ...
    ['fixOrder ~ drawingOrder*objectSize +' ...
    ' (drawingOrder*objectSize|subject) +' ...
    ' (drawingOrder*objectSize|sceneCategory)']);
disp(['R square adjusted for both categories combined: ', num2str(lme_full.Rsquared.Adjusted)])
anovaResultsCombined = anova(lme_full);
disp(anovaResultsCombined)

%% variance partitioning 

% Reduced models
lme_noobj  = fitlme(superLongTable, ['fixOrder ~ drawingOrder + objectSize:drawingOrder +' ...
    ' (drawingOrder + objectSize:drawingOrder|subject) +' ...
    ' (drawingOrder + objectSize:drawingOrder|sceneCategory)']);
lme_nodraw = fitlme(superLongTable, ['fixOrder ~ objectSize + objectSize:drawingOrder +' ...
    ' (objectSize + objectSize:drawingOrder |subject) +' ...
    ' (objectSize + objectSize:drawingOrder |sceneCategory)']);
lme_noInt  = fitlme(superLongTable, ['fixOrder ~ drawingOrder + objectSize +' ...
    ' (drawingOrder + objectSize|subject) +' ...
    ' (drawingOrder + objectSize|sceneCategory)']);

% get R square
r2_full     = lme_full.Rsquared.Ordinary;
r2_noobj    = lme_noobj.Rsquared.Ordinary;
r2_nodraw   = lme_nodraw.Rsquared.Ordinary;
r2_noInt    = lme_noInt.Rsquared.Ordinary;

% estimate variance contributions
var_DrawOrder  = r2_full - r2_nodraw
var_ObjSize    = r2_full - r2_noobj
var_Interaction = r2_full - r2_noInt

% sizes based on contributions (scale for visibility)
A = 1:round(var_DrawOrder*1000); 
B = (A(end)+1:A(end)+round(var_ObjSize*1000))-round(var_Interaction*1000); 

% make figure
figure
setListData = {A, B};
h = vennEulerDiagram(setListData, [], 'drawProportional', true);

end 