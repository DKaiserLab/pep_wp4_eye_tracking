function d = getAccuracyMemoryTask(cfg, d)

% Initialize arrays to store mean accuracies
d.memoryTask.kitchenAll = [];
d.memoryTask.bathroomAll = [];
d.memoryTask.kitchenMeans = [];
d.memoryTask.bathroomMeans = [];
sourcedataDir = fullfile(pwd, '..', 'sourcedata');

% Loop through each subject
for i = 1:length(cfg.subNums)
    subNum = cfg.subNums(i);

    % Construct file path
    filePath = fullfile(sourcedataDir, sprintf('sub-%03d', subNum), sprintf('memory_task_sub-%03d.csv', subNum));

    % Check if file exists
    if ~isfile(filePath)
        warning('File not found: %s', filePath);

        d.memoryTask.kitchenAll(end+1, :) = nan(75, 1);
        d.memoryTask.bathroomAll(end+1, :) = nan(75, 1);
        d.memoryTask.kitchenMeans(end+1) = NaN;
        d.memoryTask.bathroomMeans(end+1) = NaN; % 'bahtroom' typo kept as in data
    else

        % Load CSV file as a table
        data = readtable(filePath, 'Delimiter', ',');

        % Extract accuracy (2nd to last column) and category (last column)
        accuracy = table2array(data(:, end-1));  % Convert to numerical array
        category = string(data{:, end});  % Convert last column to string array

        % Compute means for kitchen and bathroom
        d.memoryTask.kitchenAll(end+1, :) = accuracy(category == "kitchen");
        d.memoryTask.bathroomAll(end+1, :) = accuracy(category == "bahtroom");
        d.memoryTask.kitchenMeans(end+1) = mean(accuracy(category == "kitchen"), 'omitnan');
        d.memoryTask.bathroomMeans(end+1) = mean(accuracy(category == "bahtroom"), 'omitnan'); % 'bahtroom' typo kept as in data
    end
end

% Compute ISC
cfg.plotting = false;
idx = length(d.kitchen_RDM.ratingRDM) + 1;
[~, rdm, ~] = make_RDM(d.memoryTask.kitchenAll', cfg);
d.kitchen_RDM.ratingRDM(idx).name = 'MemoryAccuracy';
d.kitchen_RDM.ratingRDM(idx).color = [0, 0, 0];
d.kitchen_RDM.ratingRDM(idx).RDM = rdm;
[~, rdm, ~] = make_RDM(d.memoryTask.bathroomAll', cfg);
d.bathroom_RDM.ratingRDM(idx).name = 'MemoryAccuracy';
d.bathroom_RDM.ratingRDM(idx).color = [0, 0, 0];
d.bathroom_RDM.ratingRDM(idx).RDM = rdm;

% Compute group means
meanKitchen = mean(d.memoryTask.kitchenMeans, 'omitnan');
meanBathroom = mean(d.memoryTask.bathroomMeans, 'omitnan');

% Compute standard error (SEM = std / sqrt(n))
semKitchen = std(d.memoryTask.kitchenMeans, 'omitnan') / sqrt(length(d.memoryTask.kitchenMeans));
semBathroom = std(d.memoryTask.bathroomMeans, 'omitnan') / sqrt(length(d.memoryTask.bathroomMeans));

% stats including False Discovery Rate (FDR) correction
[~, pv] = ttest([d.memoryTask.kitchenMeans', d.memoryTask.bathroomMeans'], 0, 'tail', 'right');
[~, ~, ~, adj_pv] = fdr_bh(pv);

% Plot bar chart with error bars and scatter dots
figure;
hold on;

barHandles = bar([1, 2], [meanKitchen, meanBathroom], 'FaceColor', 'flat');  % Bar plot for means

% Add error bars
errorbar([1, 2], [meanKitchen, meanBathroom], [semKitchen, semBathroom], 'k', 'LineStyle', 'none', 'LineWidth', 1.5);

% Scatter individual subject values
scatter(ones(size(d.memoryTask.kitchenMeans)), d.memoryTask.kitchenMeans, 10,...
    'MarkerEdgeColor', 'k', 'jitter', 'on', 'jitterAmount', 0.1);
scatter(2 * ones(size(d.memoryTask.bathroomMeans)), d.memoryTask.bathroomMeans, 10,...
    'MarkerEdgeColor', 'k', 'jitter', 'on', 'jitterAmount', 0.1);

% Add horizontal line at chance level
yline(0.5, '--r', 'Chance Level', 'LineWidth', 1.5, 'LabelHorizontalAlignment', 'right');

% add asterisks
text(1-0.1, max(d.memoryTask.kitchenMeans) + 0.05, pval2asterisks(adj_pv(1)), 'FontSize', 15, 'FontWeight', 'bold')
text(2-0.1, max(d.memoryTask.bathroomMeans) + 0.05, pval2asterisks(adj_pv(2)), 'FontSize', 15, 'FontWeight', 'bold')

% Customize plot
ylim([0.3,0.9])
xticks([1, 2]);
xticklabels({'Kitchen', 'Bathroom'});
ylabel('Mean Accuracy');
title('Accuracy in Kitchen vs. Bathroom Trials');
hold off;

% combine categories
avgAccuracies = [d.memoryTask.kitchenMeans; d.memoryTask.bathroomMeans];
meanAvgAcc = mean(avgAccuracies);
[~, pvAvg] = ttest(meanAvgAcc', 0, 'tail', 'right');

% display results
disp(newline)
disp('Bathroom')
disp(['Mean accuracy: ', num2str(meanBathroom)])
disp(['P value t-test: ', num2str(pv(2))])

disp(newline)
disp('Kitchen')
disp(['Mean accuracy: ', num2str(meanKitchen)])
disp(['P value t-test: ', num2str(pv(1))])

disp(newline)
disp('Combined')
disp(['Mean accuracy: ', num2str(mean(meanAvgAcc))])
disp(['Std of accuracy: ', num2str(std(meanAvgAcc))])
disp(['P value t-test: ', num2str(pvAvg)])

end
