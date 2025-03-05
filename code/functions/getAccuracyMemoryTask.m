function d = getAccuracyMemoryTask(cfg, d)

% Initialize arrays to store mean accuracies
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
        continue;
    end

    % Load CSV file as a table
    data = readtable(filePath, 'Delimiter', ',');

    % Extract accuracy (2nd to last column) and category (last column)
    accuracy = table2array(data(:, end-1));  % Convert to numerical array
    category = string(data{:, end});  % Convert last column to string array

    % Compute means for kitchen and bathroom
    d.memoryTask.kitchenMeans(end+1) = mean(accuracy(category == "kitchen"), 'omitnan');
    d.memoryTask.bathroomMeans(end+1) = mean(accuracy(category == "bahtroom"), 'omitnan'); % 'bahtroom' typo kept as in data
end

% Compute group means
meanKitchen = mean(d.memoryTask.kitchenMeans, 'omitnan');
meanBathroom = mean(d.memoryTask.bathroomMeans, 'omitnan');

% Compute standard error (SEM = std / sqrt(n))
semKitchen = std(d.memoryTask.kitchenMeans, 'omitnan') / sqrt(length(d.memoryTask.kitchenMeans));
semBathroom = std(d.memoryTask.bathroomMeans, 'omitnan') / sqrt(length(d.memoryTask.bathroomMeans));

% Plot bar chart with error bars and scatter dots
figure;
hold on;
barHandles = bar([1, 2], [meanKitchen, meanBathroom], 'FaceColor', 'flat');  % Bar plot for means

% Add error bars
errorbar([1, 2], [meanKitchen, meanBathroom], [semKitchen, semBathroom], 'k', 'LineStyle', 'none', 'LineWidth', 1.5);

% Scatter individual subject values
scatter(ones(size(d.memoryTask.kitchenMeans)), d.memoryTask.kitchenMeans, 50, 'k', 'filled', 'jitter', 'on', 'jitterAmount', 0.1);
scatter(2 * ones(size(d.memoryTask.bathroomMeans)), d.memoryTask.bathroomMeans, 50, 'k', 'filled', 'jitter', 'on', 'jitterAmount', 0.1);

% Customize plot
xticks([1, 2]);
xticklabels({'Kitchen', 'Bathroom'});
ylabel('Mean Accuracy');
title('Accuracy in Kitchen vs. Bathroom Trials');
grid on;
hold off;
end
