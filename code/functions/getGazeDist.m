function d = getGazeDist(d, cfg)

% Define directories and files
dataDir = fullfile(pwd, '..', 'derivatives');
files = dir(fullfile(dataDir, 'sub-*_task-EyeTracking_physio_R*.txt'));

% get log file (trial order is identical across subjects)
log_file = readtable(fullfile(pwd, '..', 'sourcedata', ['sub-', num2str(cfg.subNums(1))],...
    ['sub-', num2str(cfg.subNums(1)), '_task-EyeTracking_events.tsv']),'FileType', 'text', 'Delimiter', '\t');
log_file = log_file(log_file.trial > 0,:);

% get category membership of images
imageCategoriesDir = fullfile(pwd, '..', 'imageCategories.csv');
imageCategoriesFile = readtable(imageCategoriesDir,'Format','auto');

% add category to logFile 
log_file.category = repmat({'cate'}, height(log_file), 1);
for iRow = 1:height(log_file)
    cateIdx = find(strcmp(log_file.image{iRow}, imageCategoriesFile.FileName));
    log_file.category{iRow} = imageCategoriesFile.FolderName{cateIdx};
end 
bathImgs = log_file.trial(strcmp(log_file.category, 'bathroom'))'; 
kitImgs = log_file.trial(strcmp(log_file.category, 'kitchen'))';

% Initialize results
bath_dists = nan(length(bathImgs), cfg.n, cfg.n);
kit_dists = nan(length(kitImgs), cfg.n, cfg.n);

for i = 1:height(log_file)
    
    % runtime control
    disp(['Processing trial ', num2str(i), ' with image ', log_file.image{i}])

    % Load gaze data from all subjects for this image
    gazeData = cell(1, cfg.n);
    allData = cell(1, cfg.n);
    for s = 1:cfg.n
        dataFilePath = fullfile(dataDir, sprintf('sub-%03d', cfg.subNums(s)), 'samples',...
            sprintf('sub-%03d_task-EyeTracking_physio_R%03d.txt', cfg.subNums(s), i));
        data = readtable(dataFilePath, 'Delimiter', '\t');

        % Remove fixation period 
        msgsFilePath = fullfile(dataDir, sprintf('sub-%03d', cfg.subNums(s)), 'msgs',...
            sprintf('sub-%03d_task-EyeTracking_physio_R%03d.txt', cfg.subNums(s), i));
        msgs = readtable(msgsFilePath, 'Delimiter', '\t');
        msgIdx = find(contains(msgs.Var2, 'STIM ON'));
        data = data(data.t >= msgs.Var1(msgIdx) & data.t <= msgs.Var1(msgIdx+1), :);
        data.t = (data.t - data.t(1))*0.000001;

        % Combine left and right gaze points
        x = mean([data.gaze_point_LX, data.gaze_point_RX], 2, 'omitnan');
        y = mean([data.gaze_point_LY, data.gaze_point_RY], 2, 'omitnan');

        gazeData{s} = [x y];
        allData{s} = data;
    end

    % Make all trajectories the same length
    minLen = min(cellfun(@(x) size(x,1), gazeData));
    if minLen < 10
        warning('Skipping image R%03d due to insufficient data.', imageID);
        continue
    end
    gazeData = cellfun(@(x) x(1:minLen,:), gazeData, 'UniformOutput', false);
    gazeMatrix = cat(3, gazeData{:}); % [time x 2 x subj]

    % Pairwise Euclidean distances
    nSubs = cfg.n;
    pairDists = zeros(cfg.n, cfg.n);
    if isempty(gcp('nocreate'))
        parpool(8);
    end
    parfor a = 1:nSubs
        for b = 1:nSubs
            if a <= b
                continue
            end 
            trajA = squeeze(gazeMatrix(:,:,a));
            trajB = squeeze(gazeMatrix(:,:,b));
            dist = sqrt(sum((trajA - trajB).^2, 2));
            pairDists(a,b) = median(dist, 'omitnan');
        end
    end
    pairDists = squareform(squareform(pairDists));

    % Store by category
    if ismember(i, bathImgs)
        idx = find(i == bathImgs);
        bath_dists(idx, :, :) = pairDists;
    elseif ismember(i, kitImgs)
        idx = find(i == kitImgs);
        kit_dists(idx, :, :) = pairDists;
    end
end

% Final results: mean across images per category
d.kitchen_RDM.ratingRDM(end+1).RDM = squeeze(mean(kit_dists, 'omitnan'))/...
    max(kit_dists,[], 'all');
d.kitchen_RDM.ratingRDM(end).name = 'GazeDist';
d.kitchen_RDM.ratingRDM(end).color = [0, 0, 0]';
d.bathroom_RDM.ratingRDM(end+1).RDM = squeeze(mean(bath_dists, 'omitnan'))/...
    max(bath_dists,[], 'all');
d.bathroom_RDM.ratingRDM(end).name = 'GazeDist';
d.bathroom_RDM.ratingRDM(end).color = [0, 0, 0]';

if ~isempty(gcp('nocreate'))
    delete(gcp('nocreate'));
end

end