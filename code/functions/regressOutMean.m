function d = regressOutMean(d, cfg)

% loop through categories
for iCate = 1:length(cfg.categories)
    % get category
    category = cfg.categories{iCate};

    % copy isOdd variable
    d.GDM_demeaned.(category).isOdd = d.GDM.(category).isOdd;

    count = 0;
    for voi = cfg.variables_of_interest
        count = count + 1;
        task = char(voi);

        % get result table for each task
        sub_table = array2table(d.GDM.(category).(task)');

        % get mean
        sub_table = table2array(sub_table);
        groupMean = mean(sub_table, 2);

        % loop through subjects and regress out mean
        regressedTimecourses = zeros(size(sub_table)); % Initialize
        for iSub = 1:cfg.n
            % Design matrix: group-average timecourse and intercept
            X = [groupMean, ones(height(sub_table), 1)];
            % Perform regression
            beta = X \ sub_table(:, iSub); % Compute coefficients
            predicted = X * beta; % Predicted values based on the group average
            % Residual (subject timecourse with group average regressed out)
            regressedTimecourses(:, iSub) = sub_table(:, iSub) - predicted;
        end

        % overwrite the subject table
        d.GDM_demeaned.(category).(task) = regressedTimecourses';

    end
end
end