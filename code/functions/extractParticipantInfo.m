function cfg = extractParticipantInfo(cfg)

% Base directory (adjust if needed)
baseDir = fullfile(pwd, '..', 'sourcedata');

ages = [];
genders = strings(0);

for i = 1:length(cfg.subNums)

    subNum = cfg.subNums(i);

    % Build path
    subFolder = fullfile(baseDir, sprintf('sub-%03d', subNum));
    jsonFile  = fullfile(subFolder, ...
        sprintf('sub-%03d_task-EyeTracking_participants.json', subNum));

    if ~isfile(jsonFile)
        warning('File not found: %s', jsonFile);
        continue
    end

    % Read JSON
    jsonText = fileread(jsonFile);
    data = jsondecode(jsonText);

    % ---- Adjust field names if necessary ----
    % Example assumes fields are called "age" and "gender"
    if isfield(data, 'age')
        ages(length(ages)+1) = str2double(data.age);
    end

    if isfield(data, 'gender')
        genders(length(genders)+1) = string(lower(data.gender));
    end
end

% ---- Compute statistics ----
cfg.sample.nSubjects = length(ages);
cfg.sample.meanAge   = mean(ages, 'omitnan');
cfg.sample.sdAge     = std(ages, 'omitnan');

% Gender balance
cfg.sample.nFemale = sum(genders == "female");
cfg.sample.nMale   = sum(genders == "male");
cfg.sample.nOther  = sum(~ismember(genders, ["female","male"]));

cfg.sample.genderBalance = struct( ...
    'female', cfg.sample.nFemale, ...
    'male',   cfg.sample.nMale, ...
    'other',  cfg.sample.nOther);

% Store raw vectors as well
cfg.sample.ages    = ages;
cfg.sample.genders = genders;

fprintf('Subjects: %d\n', cfg.sample.nSubjects);
fprintf('Mean age: %.2f (SD = %.2f)\n', cfg.sample.meanAge, cfg.sample.sdAge);
fprintf('Gender: %d female, %d male, %d other\n', ...
    cfg.sample.nFemale, cfg.sample.nMale, cfg.sample.nOther);

end