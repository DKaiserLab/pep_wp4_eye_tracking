function d = getGazeDist(d, cfg)

if ~isfield(cfg, 'stimDur'); cfg.stimDur = 3; end
if ~isfield(cfg, 'ETSamplingFrequency'); cfg.ETSamplingFrequency = 120; end % in Hz
if ~isfield(cfg, 'binSize'); cfg.binSize = 0.05; end % in sec

% check if files exist
dataDir = fullfile(pwd, '..', 'derivatives', 'groupLevel', 'gazeDist', ['exp_', cfg.exp_name]);
allExist = (exist(fullfile(dataDir, 'meanBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanKitDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanOddBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEvenBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanOddKitDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEvenKitDists.mat'), 'file'));

% exist(fullfile(dataDir, 'binnedBatDists.mat'), 'file') && ...
% exist(fullfile(dataDir, 'binnedKitDists.mat'), 'file') && ...
    

% if data exist already load it
if allExist

    % kitchen
    if isfield(d, "kitchen_RDM")
        idx = length({d.kitchen_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end
    load(fullfile(dataDir, 'meanKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx).RDM = meanKitDists;
    d.kitchen_RDM.ratingRDM(idx).name = 'GazeDist';
    d.kitchen_RDM.ratingRDM(idx).color = [0, 0, 0]';

    % bined distances
%     load(fullfile(dataDir, 'binnedKitDists.mat'));
%     d.kitchen_RDM.ratingRDM(idx+1).RDM = binnedKitDists;
%     d.kitchen_RDM.ratingRDM(idx+1).name = 'binedGazeDist';
%     d.kitchen_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

    % odd distances
    load(fullfile(dataDir, 'meanOddKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+2).RDM = meanOddKitDists;
    d.kitchen_RDM.ratingRDM(idx+2).name = 'meanOddKitDists';
    d.kitchen_RDM.ratingRDM(idx+2).color = [0, 0, 0]';

    % odd distances
    load(fullfile(dataDir, 'meanEvenKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+3).RDM = meanEvenKitDists;
    d.kitchen_RDM.ratingRDM(idx+3).name = 'meanEvenKitDists';
    d.kitchen_RDM.ratingRDM(idx+3).color = [0, 0, 0]';

    % bathroom
    if isfield(d, "bathroom_RDM")
        idx = length({d.bathroom_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end
    load(fullfile(dataDir, 'meanBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx).RDM = meanBatDists;
    d.bathroom_RDM.ratingRDM(idx).name = 'GazeDist';
    d.bathroom_RDM.ratingRDM(idx).color = [0, 0, 0]';

    % bined distances
%     load(fullfile(dataDir, 'binnedBatDists.mat'));
%     d.bathroom_RDM.ratingRDM(idx+1).RDM = binnedBatDists;
%     d.bathroom_RDM.ratingRDM(idx+1).name = 'binedGazeDist';
%     d.bathroom_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

     % odd distances
    load(fullfile(dataDir, 'meanOddBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+2).RDM = meanOddBatDists;
    d.bathroom_RDM.ratingRDM(idx+2).name = 'meanOddBatDists';
    d.bathroom_RDM.ratingRDM(idx+2).color = [0, 0, 0]';

    % odd distances
    load(fullfile(dataDir, 'meanEvenBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+3).RDM = meanEvenBatDists;
    d.bathroom_RDM.ratingRDM(idx+3).name = 'meanEvenBatDists';
    d.bathroom_RDM.ratingRDM(idx+3).color = [0, 0, 0]';

    disp('Data exist already')

else
    % Define directories and files
    dataDir = fullfile(pwd, '..', 'derivatives');
    files = dir(fullfile(dataDir, 'sub-*_task-EyeTracking_physio_R*.txt'));

    % get log file (trial order is identical across subjects)
    log_file = readtable(fullfile(pwd, '..', 'sourcedata', sprintf('sub-%03d', cfg.subNums(1)),...
        [sprintf('sub-%03d', cfg.subNums(1)), '_task-EyeTracking_events.tsv']),'FileType', 'text', 'Delimiter', '\t');
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
    nTimesteps = cfg.stimDur*cfg.ETSamplingFrequency;
    bathDists = nan(length(bathImgs), cfg.n, cfg.n);
    d.bathDistsAll = nan(length(kitImgs), cfg.n, cfg.n, nTimesteps);
    kitDists = bathDists;
    d.kitDistsAll = d.bathDistsAll;

    for i = 1:height(log_file)

        % runtime control
        disp(['Processing trial ', num2str(i), ' with image ', log_file.image{i}])

        % Load gaze data from all subjects for this image
        gazeData = cell(1, cfg.n);
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
        pairDistsAll = zeros(cfg.n, cfg.n, size(gazeMatrix, 1));
        if isempty(gcp('nocreate'))
            parpool(10);
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
                pairDistsAll(a,b,:) = dist;
            end
        end
        pairDists = squareform(squareform(pairDists));

        % Store by category
        if ismember(i, bathImgs)
            idx = find(i == bathImgs);
            bathDists(idx, :, :) = pairDists;
            d.bathDistsAll(idx, :, :, 1:length(pairDistsAll)) = pairDistsAll;
        elseif ismember(i, kitImgs)
            idx = find(i == kitImgs);
            kitDists(idx, :, :) = pairDists;
            d.kitDistsAll(idx, :, :, 1:length(pairDistsAll)) = pairDistsAll;
        end
    end

    % get RDM for time bins
    tpPerBin = round(cfg.binSize/(1/cfg.ETSamplingFrequency));
    nBins = nTimesteps - tpPerBin;

    % get mean dist for each bin
    binedDistBath = nan(length(kitImgs), cfg.n, cfg.n, nBins);
    binedDistKit = nan(length(kitImgs), cfg.n, cfg.n, nBins);
    for iBin = 1:nBins
        binSample = d.bathDistsAll(:, :, :, iBin:iBin+tpPerBin-1);
        binedDistBath(:, :, :, iBin) = mean(binSample, 4, 'omitnan');
        binSample = d.kitDistsAll(:, :, :, iBin:iBin+tpPerBin-1);
        binedDistKit(:, :, :, iBin) = mean(binSample, 4, 'omitnan');
    end

    %% store data
    dataDir = fullfile(pwd, '..', 'derivatives', 'groupLevel', 'gazeDist', ['exp_', cfg.exp_name]);
    if ~exist(dataDir, 'dir')
        mkdir(dataDir)
    end 

    % mean across images per category
    % kitchen
    if isfield(d, "kitchen_RDM")
        idx = length({d.kitchen_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end

    meanKitDists = squeeze(mean(kitDists, 'omitnan'))/...
        max(kitDists,[], 'all');
    d.kitchen_RDM.ratingRDM(idx).RDM = meanKitDists;
    d.kitchen_RDM.ratingRDM(idx).name = 'GazeDist';
    d.kitchen_RDM.ratingRDM(idx).color = [0, 0, 0]';

    % bined distances
%     binnedKitDists = squeeze(mean(binedDistKit, 'omitnan'))/...
%         max(binedDistKit,[], 'all');
%     d.kitchen_RDM.ratingRDM(idx+1).RDM = binnedKitDists;
%     d.kitchen_RDM.ratingRDM(idx+1).name = 'binedGazeDist';
%     d.kitchen_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

    % save
%     save(fullfile(dataDir, 'meanKitDists.mat'), 'meanKitDists');
%     save(fullfile(dataDir, 'binnedKitDists.mat'), 'binnedKitDists');

    % bathroom
    if isfield(d, "bathroom_RDM")
        idx = length({d.bathroom_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end
    meanBatDists = squeeze(mean(bathDists, 'omitnan'))/...
        max(bathDists,[], 'all');
    d.bathroom_RDM.ratingRDM(idx).RDM = meanBatDists;
    d.bathroom_RDM.ratingRDM(idx).name = 'GazeDist';
    d.bathroom_RDM.ratingRDM(idx).color = [0, 0, 0]';

    % bined distances
%     binnedBatDists = squeeze(mean(binedDistKit, 'omitnan'))/...
%         max(binedDistKit,[], 'all');
%     d.bathroom_RDM.ratingRDM(idx+1).RDM = binnedBatDists;
%     d.bathroom_RDM.ratingRDM(idx+1).name = 'binedGazeDist';
%     d.bathroom_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

    % save
%     save(fullfile(dataDir, 'meanBatDists.mat'), 'meanBatDists');
%     save(fullfile(dataDir, 'binnedBatDists.mat'), 'binnedBatDists');

    %% split odd and even

    % bathroom
    oddBatDist = bathDists(1:2:size(bathDists, 1), :, :);
    meanOddBatDists = squeeze(mean(oddBatDist, 'omitnan'))/...
        max(bathDists,[], 'all');
    d.bathroom_RDM.ratingRDM(idx+2).RDM = meanOddBatDists;
    d.bathroom_RDM.ratingRDM(idx+2).name = 'meanOddBatDists';
    d.bathroom_RDM.ratingRDM(idx+2).color = [0, 0, 0]';
    save(fullfile(dataDir, 'meanOddBatDists.mat'), 'meanOddBatDists');

    evenBatDist = bathDists(2:2:size(bathDists, 1), :, :);
    meanEvenBatDists = squeeze(mean(evenBatDist, 'omitnan'))/...
        max(bathDists,[], 'all');
    d.bathroom_RDM.ratingRDM(idx+3).RDM = meanEvenBatDists;
    d.bathroom_RDM.ratingRDM(idx+3).name = 'meanEvenBatDists';
    d.bathroom_RDM.ratingRDM(idx+3).color = [0, 0, 0]';
    save(fullfile(dataDir, 'meanEvenBatDists.mat'), 'meanEvenBatDists');

    % kitchen
    oddKitDist = kitDists(1:2:size(kitDists, 1), :, :);
    meanOddKitDists = squeeze(mean(oddKitDist, 'omitnan'))/...
        max(kitDists,[], 'all');
    d.kitchen_RDM.ratingRDM(idx+2).RDM = meanOddKitDists;
    d.kitchen_RDM.ratingRDM(idx+2).name = 'meanOddKitDists';
    d.kitchen_RDM.ratingRDM(idx+2).color = [0, 0, 0]';
    save(fullfile(dataDir, 'meanOddKitDists.mat'), 'meanOddKitDists');

    evenKitDist = kitDists(2:2:size(kitDists, 1), :, :);
    meanEvenKitDists = squeeze(mean(evenKitDist, 'omitnan'))/...
        max(kitDists,[], 'all');
    d.kitchen_RDM.ratingRDM(idx+3).RDM = meanEvenKitDists;
    d.kitchen_RDM.ratingRDM(idx+3).name = 'meanEvenKitDists';
    d.kitchen_RDM.ratingRDM(idx+3).color = [0, 0, 0]';
    save(fullfile(dataDir, 'meanEvenKitDists.mat'), 'meanEvenKitDists');


end

end