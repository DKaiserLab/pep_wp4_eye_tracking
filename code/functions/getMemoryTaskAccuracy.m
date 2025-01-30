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
    fileName = sprintf('memory_task_sub-%0.3d.mat', sub);
    filePath = fullfile(subjectPath, fileName);
    loadedData = load(filePath);
    
    % Extract accuracy values from dat.results
    accuracyCell = loadedData.dat.results(:, 5);  % Column 5 contains accuracy
    accuracyVector = str2double(accuracyCell);    % Convert to numeric values
    
    % Compute mean accuracy
    meanAccuracy = mean(accuracyVector); 
    
    % Store results in arrays
    subjectIDs{end+1} = loadedData.dat.subjctNumber;  % Store subject number
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