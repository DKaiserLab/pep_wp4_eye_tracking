function resultsTable = getMemoryTaskAccuracy(subs)

% Define the data directory 
baseDir = fullfile(pwd, '..', 'sourcedata');  % Replace with the actual path

% Initialize an empty table to store results
subjectIDs = {};
meanAccuracies = [];

% Loop through each subject file
for i = 1:length(subs)

    % Load the subject data
    sub = subs(i);
    subjectPath = fullfile(baseDir, sprintf('sub-%0.3d', sub));
    fileName = sprintf('memory_task_sub-%0.3d.csv', sub);
    filePath = fullfile(subjectPath, fileName);
    loadedData = readtable(filePath, 'FileType', 'text');
    
    % Compute mean accuracy
    meanAccuracy = mean(loadedData.Var5); % Column 5 contains accuracy
    
    % Store results in arrays
    subjectIDs{end+1} = num2str(sub);  % Store subject number
    meanAccuracies(end+1) = meanAccuracy;             % Store mean accuracy
end

% Create the results table
resultsTable = table(subjectIDs', meanAccuracies', 'VariableNames', {'SubjectID', 'MeanAccuracy'});

% Calculate group statistics
meanAcrossSubjects = mean(meanAccuracies);
stdAcrossSubjects = std(meanAccuracies);

% Append mean and std as additional rows
resultsTable = [resultsTable; 
                table({'Mean'}, meanAcrossSubjects, 'VariableNames', {'SubjectID', 'MeanAccuracy'});
                table({'Std'}, stdAcrossSubjects, 'VariableNames', {'SubjectID', 'MeanAccuracy'})];

end