function d = getGazeDist(d, cfg)

if ~isfield(cfg, 'stimDur'); cfg.stimDur = 3; end
if ~isfield(cfg, 'ETSamplingFrequency'); cfg.ETSamplingFrequency = 120; end % in Hz
if ~isfield(cfg, 'binSize'); cfg.binSize = 0.05; end % in sec
if ~isfield(cfg, 'calculateMannanDist'); cfg.calculateMannanDist = true; end
if ~isfield(cfg, 'force_recompute'); cfg.force_recompute = false; end


% check if files exist
dataDir = fullfile(pwd, '..', 'derivatives', 'groupLevel', 'gazeDist', ['exp_', cfg.exp_name]);
allExist = (exist(fullfile(dataDir, 'meanBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanKitDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanOddBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEvenBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanOddKitDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEvenKitDists.mat'), 'file')) && ...
    exist(fullfile(dataDir, 'meanLateBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEarlyBatDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanLateKitDists.mat'), 'file') && ...
    exist(fullfile(dataDir, 'meanEarlyKitDists.mat'), 'file');

% Mannan distances are additionally checked
if cfg.calculateMannanDist
    allExist = allExist && ...
        exist(fullfile(dataDir, 'meanMannanBatDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanMannanKitDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanOddKitMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanOddBatMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanEvenKitMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanEvenBatMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanLateKitMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanLateBatMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanEarlyKitMannanDists.mat'), 'file') && ...
        exist(fullfile(dataDir, 'meanEarlyBatMannanDists.mat'), 'file');
end

% if data exist already load it
if allExist && ~cfg.force_recompute

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

    if cfg.calculateMannanDist
        load(fullfile(dataDir, 'meanMannanKitDists.mat'));
        d.kitchen_RDM.ratingRDM(idx+1).RDM = meanMannanKitDists;
        d.kitchen_RDM.ratingRDM(idx+1).name = 'MannanDist';
        d.kitchen_RDM.ratingRDM(idx+1).color = [0, 0, 0]';
    end

    if strcmp(cfg.exp_name, 'combined')
        [d.compareExps.kitchen.GazeDist.res] = compare_experiments_is_rdms(...
            meanKitDists, cfg.n_permutations, 'GazeDist');

        if cfg.calculateMannanDist
            [d.compareExps.kitchen.MannanDist.res] = compare_experiments_is_rdms(...
                meanMannanKitDists, cfg.n_permutations, 'MannanDist');
        end
    end

    % odd distances
    load(fullfile(dataDir, 'meanOddKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+2).RDM = meanOddKitDists;
    d.kitchen_RDM.ratingRDM(idx+2).name = 'meanOddKitDists';
    d.kitchen_RDM.ratingRDM(idx+2).color = [0, 0, 0]';

    % even distances
    load(fullfile(dataDir, 'meanEvenKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+3).RDM = meanEvenKitDists;
    d.kitchen_RDM.ratingRDM(idx+3).name = 'meanEvenKitDists';
    d.kitchen_RDM.ratingRDM(idx+3).color = [0, 0, 0]';

    % late distances
    load(fullfile(dataDir, 'meanLateKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+4).RDM = meanLateKitDists;
    d.kitchen_RDM.ratingRDM(idx+4).name = 'meanLateKitDists';
    d.kitchen_RDM.ratingRDM(idx+4).color = [0, 0, 0]';

    % early distances
    load(fullfile(dataDir, 'meanEarlyKitDists.mat'));
    d.kitchen_RDM.ratingRDM(idx+5).RDM = meanEarlyKitDists;
    d.kitchen_RDM.ratingRDM(idx+5).name = 'meanEarlyKitDists';
    d.kitchen_RDM.ratingRDM(idx+5).color = [0, 0, 0]';

    if cfg.calculateMannanDist
        % odd Mannan distances
        load(fullfile(dataDir, 'meanOddKitMannanDists.mat'));
        d.kitchen_RDM.ratingRDM(idx+6).RDM = meanOddKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+6).name = 'meanOddKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+6).color = [0, 0, 0]';

        % even Mannan distances
        load(fullfile(dataDir, 'meanEvenKitMannanDists.mat'));
        d.kitchen_RDM.ratingRDM(idx+7).RDM = meanEvenKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+7).name = 'meanEvenKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+7).color = [0, 0, 0]';

        % late Mannan distances
        load(fullfile(dataDir, 'meanLateKitMannanDists.mat'));
        d.kitchen_RDM.ratingRDM(idx+8).RDM = meanLateKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+8).name = 'meanLateKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+8).color = [0, 0, 0]';

        % early Mannan distances
        load(fullfile(dataDir, 'meanEarlyKitMannanDists.mat'));
        d.kitchen_RDM.ratingRDM(idx+9).RDM = meanEarlyKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+9).name = 'meanEarlyKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+9).color = [0, 0, 0]';
    end

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

    if cfg.calculateMannanDist
        load(fullfile(dataDir, 'meanMannanBatDists.mat'));
        d.bathroom_RDM.ratingRDM(idx+1).RDM = meanMannanBatDists;
        d.bathroom_RDM.ratingRDM(idx+1).name = 'MannanDist';
        d.bathroom_RDM.ratingRDM(idx+1).color = [0, 0, 0]';
    end

    if strcmp(cfg.exp_name, 'combined')
        [d.compareExps.bathroom.GazeDist.res] = compare_experiments_is_rdms(...
            meanBatDists, cfg.n_permutations, 'GazeDist');

        if cfg.calculateMannanDist
            [d.compareExps.bathroom.MannanDist.res] = compare_experiments_is_rdms(...
                meanMannanBatDists, cfg.n_permutations, 'MannanDist');
        end
    end

    % odd distances
    load(fullfile(dataDir, 'meanOddBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+2).RDM = meanOddBatDists;
    d.bathroom_RDM.ratingRDM(idx+2).name = 'meanOddBatDists';
    d.bathroom_RDM.ratingRDM(idx+2).color = [0, 0, 0]';

    % even distances
    load(fullfile(dataDir, 'meanEvenBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+3).RDM = meanEvenBatDists;
    d.bathroom_RDM.ratingRDM(idx+3).name = 'meanEvenBatDists';
    d.bathroom_RDM.ratingRDM(idx+3).color = [0, 0, 0]';

    % late distances
    load(fullfile(dataDir, 'meanLateBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+4).RDM = meanLateBatDists;
    d.bathroom_RDM.ratingRDM(idx+4).name = 'meanLateBatDists';
    d.bathroom_RDM.ratingRDM(idx+4).color = [0, 0, 0]';

    % early distances
    load(fullfile(dataDir, 'meanEarlyBatDists.mat'));
    d.bathroom_RDM.ratingRDM(idx+5).RDM = meanEarlyBatDists;
    d.bathroom_RDM.ratingRDM(idx+5).name = 'meanEarlyBatDists';
    d.bathroom_RDM.ratingRDM(idx+5).color = [0, 0, 0]';

    if cfg.calculateMannanDist
        % odd Mannan distances
        load(fullfile(dataDir, 'meanOddBatMannanDists.mat'));
        d.bathroom_RDM.ratingRDM(idx+6).RDM = meanOddBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+6).name = 'meanOddBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+6).color = [0, 0, 0]';

        % even Mannan distances
        load(fullfile(dataDir, 'meanEvenBatMannanDists.mat'));
        d.bathroom_RDM.ratingRDM(idx+7).RDM = meanEvenBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+7).name = 'meanEvenBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+7).color = [0, 0, 0]';

        % late Mannan distances
        load(fullfile(dataDir, 'meanLateBatMannanDists.mat'));
        d.bathroom_RDM.ratingRDM(idx+8).RDM = meanLateBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+8).name = 'meanLateBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+8).color = [0, 0, 0]';

        % early Mannan distances
        load(fullfile(dataDir, 'meanEarlyBatMannanDists.mat'));
        d.bathroom_RDM.ratingRDM(idx+9).RDM = meanEarlyBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+9).name = 'meanEarlyBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+9).color = [0, 0, 0]';
    end

    disp('Data exist already')

else

    % Define directories and files
    dataDir = fullfile(pwd, '..', 'derivatives');
    files = dir(fullfile(dataDir, 'sub-*_task-EyeTracking_physio_R*.txt'));

    % get log file (trial order is identical across subjects)
    log_file = readtable(fullfile(pwd, '..', 'sourcedata', sprintf('sub-%03d', cfg.subNums(1)),...
        [sprintf('sub-%03d', cfg.subNums(1)), '_task-EyeTracking_events.tsv']),...
        'FileType', 'text', 'Delimiter', '\t');
    log_file = log_file(log_file.trial > 0,:);

    % get category membership of images
    imageCategoriesDir = fullfile(pwd, '..', 'imageCategories.csv');
    imageCategoriesFile = readtable(imageCategoriesDir,'Format','auto');

    % add category to logFile
    log_file.category = repmat({'cate'}, height(log_file), 1);
    for iRow = 1:height(log_file)
        cateIdx = find(strcmp(log_file.image{iRow}, imageCategoriesFile.FileName), 1);
        log_file.category{iRow} = imageCategoriesFile.FolderName{cateIdx};
    end

    bathImgs = find(strcmp(log_file.category, 'bathroom'));
    kitImgs = find(strcmp(log_file.category, 'kitchen'));

    % Initialize results
    nTimesteps = round(cfg.stimDur*cfg.ETSamplingFrequency);
    nBins = nTimesteps - round(cfg.binSize/(1/cfg.ETSamplingFrequency)) + 1;

    bathDists = nan(length(bathImgs), cfg.n, cfg.n);
    kitDists = nan(length(kitImgs), cfg.n, cfg.n);
    d.bathDistsAll = nan(length(bathImgs), cfg.n, cfg.n, nTimesteps);
    d.kitDistsAll = nan(length(kitImgs), cfg.n, cfg.n, nTimesteps);

    if cfg.calculateMannanDist
        bathMannanDists = nan(length(bathImgs), cfg.n, cfg.n);
        kitMannanDists = nan(length(kitImgs), cfg.n, cfg.n);
    end

    % start parallel pool
    if isempty(gcp('nocreate'))
        parpool(10);
    end

    % map trial number to category index
    bathIdx = nan(height(log_file),1);
    kitIdx = nan(height(log_file),1);
    bathIdx(bathImgs) = 1:length(bathImgs);
    kitIdx(kitImgs) = 1:length(kitImgs);

    for i = 1:height(log_file)

        % runtime control
        disp(['Processing trial ', num2str(i), ' with image ', log_file.image{i}])

        % Load gaze and fixation data from all subjects for this image
        gazeData = cell(1, cfg.n);
        fixData = struct;

        for s = 1:cfg.n

            % get AOI fix data for image and participant
            fixDataName = fullfile(pwd, '..', 'derivatives', sprintf('sub-%0.3d', cfg.subNums(s)),...
                'AOIfix', sprintf('sub-%0.3d_task-EyeTracking_physio_R%0.3d.tsv', cfg.subNums(s), i));
            warning off
            fixData.(['sub', num2str(cfg.subNums(s))]) = readtable(fixDataName,...
                'FileType', 'text', 'Delimiter', '\t');
            warning on

            % get raw gaze data
            dataFilePath = fullfile(dataDir, sprintf('sub-%03d', cfg.subNums(s)), 'samples',...
                sprintf('sub-%03d_task-EyeTracking_physio_R%03d.txt', cfg.subNums(s), i));
            data = readtable(dataFilePath, 'Delimiter', '\t');

            % Remove pre stimulus fixation period
            msgsFilePath = fullfile(dataDir, sprintf('sub-%03d', cfg.subNums(s)), 'msgs',...
                sprintf('sub-%03d_task-EyeTracking_physio_R%03d.txt', cfg.subNums(s), i));
            msgs = readtable(msgsFilePath, 'Delimiter', '\t');
            msgIdx = find(contains(msgs.Var2, 'STIM ON'), 1);

            if isempty(msgIdx) || msgIdx+1 > height(msgs)
                gazeData{s} = [];
                continue
            end

            data = data(data.t >= msgs.Var1(msgIdx) & data.t <= msgs.Var1(msgIdx+1), :);

            if isempty(data)
                gazeData{s} = [];
                continue
            end

            data.t = (data.t - data.t(1))*0.000001;

            % Combine left and right gaze points
            x = mean([data.gaze_point_LX, data.gaze_point_RX], 2, 'omitnan');
            y = mean([data.gaze_point_LY, data.gaze_point_RY], 2, 'omitnan');

            valid = isfinite(x) & isfinite(y);
            x = x(valid);
            y = y(valid);

            gazeData{s} = [x y];

        end

        % Check that enough data are available
        validSubjects = ~cellfun(@isempty, gazeData);

        if sum(validSubjects) < 2
            warning('Skipping image R%03d due to insufficient data.', i);
            continue
        end

        % Make all trajectories the same length
        minLen = min(cellfun(@(x) size(x,1), gazeData(validSubjects)));

        if minLen < 10
            warning('Skipping image R%03d due to insufficient data.', i);
            continue
        end

        gazeData(validSubjects) = cellfun(@(x) x(1:minLen,:),...
            gazeData(validSubjects), 'UniformOutput', false);

        % replace missing subjects with NaNs
        for s = find(~validSubjects)
            gazeData{s} = nan(minLen,2);
        end

        gazeMatrix = cat(3, gazeData{:}); % [time x 2 x subj]

        % Pairwise Euclidean distances
        nSubs = cfg.n;
        pairDists = nan(nSubs, nSubs);
        pairDistsAll = nan(nSubs, nSubs, minLen);

        if cfg.calculateMannanDist
            pairMannanDists = nan(nSubs, nSubs);
        end

        % only calculate lower triangle of all possible subject pairs
        parfor sA = 2:nSubs

            localPairDists = nan(1,nSubs);
            localPairDistsAll = nan(nSubs,minLen);

            if cfg.calculateMannanDist
                localMannanDists = nan(1,nSubs);

                fixA = [fixData.(['sub', num2str(cfg.subNums(sA))]).X_pix_,...
                    fixData.(['sub', num2str(cfg.subNums(sA))]).Y_pix_];
            end

            trajA = squeeze(gazeMatrix(:,:,sA));

            for sB = 1:sA-1

                trajB = squeeze(gazeMatrix(:,:,sB));

                validA = all(isfinite(trajA),2);
                validB = all(isfinite(trajB),2);

                if sum(validA) < 1 || sum(validB) < 1
                    continue
                end

                trajAvalid = trajA(validA,:);
                trajBvalid = trajB(validB,:);

                %  Euclidean trajectory distance
                dist = sqrt(sum((trajA - trajB).^2, 2));

                localPairDists(sB) = median(dist, 'omitnan');
                localPairDistsAll(sB,:) = dist;

                % Mannan / point-mapping distance
                if cfg.calculateMannanDist

                    % get fixation data for second person
                    fixB = [fixData.(['sub', num2str(cfg.subNums(sB))]).X_pix_,...
                        fixData.(['sub', num2str(cfg.subNums(sB))]).Y_pix_];

                    % remove invalid fixation positions
                    validFixA = all(isfinite(fixA),2);
                    validFixB = all(isfinite(fixB),2);

                    fixAvalid = fixA(validFixA,:);
                    fixBvalid = fixB(validFixB,:);

                    if isempty(fixAvalid) || isempty(fixBvalid)
                        continue
                    end

                    % Distance from every fixation in A to nearest fixation in B
                    D_AB = pdist2(fixAvalid, fixBvalid);
                    minDistAB = min(D_AB, [], 2);

                    % Distance from every fixation in B to nearest fixation in A
                    minDistBA = min(D_AB, [], 1)';

                    % Fixation-duration weights
                    durA = fixData.(['sub', num2str(cfg.subNums(sA))]).duration(validFixA);
                    durB = fixData.(['sub', num2str(cfg.subNums(sB))]).duration(validFixB);

                    % Weighted mean nearest-neighbour distance
                    meanAB = sum(minDistAB .* durA) / sum(durA);
                    meanBA = sum(minDistBA .* durB) / sum(durB);

                    % Symmetric Mannan distance
                    localMannanDists(sB) = (meanAB + meanBA) / 2;

                end
            end

            pairDists(sA,:) = localPairDists;
            pairDistsAll(sA,:,:) = localPairDistsAll;

            if cfg.calculateMannanDist
                pairMannanDists(sA,:) = localMannanDists;
            end
        end

        % make matrices symmetric
        pairDists(eye(size(pairDists)) == 1) = 0;
        pairDists = squareform(squareform(pairDists));

        for tp = 1:size(pairDistsAll,3)
            tpDists = squeeze(pairDistsAll(:, :, tp));
            tpDists(eye(size(tpDists)) == 1) = 0;
            pairDistsAll(:, :, tp) = squareform(squareform(tpDists));
        end

        if cfg.calculateMannanDist
            pairMannanDists(eye(size(pairMannanDists)) == 1) = 0;
            pairMannanDists = squareform(squareform(pairMannanDists));
        end

        % Store by category
        if bathIdx(i) > 0

            idx = bathIdx(i);
            bathDists(idx,:,:) = pairDists;
            d.bathDistsAll(idx,:,:,1:size(pairDistsAll,3)) = pairDistsAll;

            if cfg.calculateMannanDist
                bathMannanDists(idx,:,:) = pairMannanDists;
            end

        elseif kitIdx(i) > 0

            idx = kitIdx(i);
            kitDists(idx,:,:) = pairDists;
            d.kitDistsAll(idx,:,:,1:size(pairDistsAll,3)) = pairDistsAll;

            if cfg.calculateMannanDist
                kitMannanDists(idx,:,:) = pairMannanDists;
            end
        end
    end

    %% get RDM for time bins
    tpPerBin = round(cfg.binSize/(1/cfg.ETSamplingFrequency));
    nBins = nTimesteps - tpPerBin + 1;

    % get mean dist for each bin
    binedDistBath = nan(length(bathImgs), cfg.n, cfg.n, nBins);
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

    %% mean across images per category

    % kitchen
    if isfield(d, "kitchen_RDM")
        idx = length({d.kitchen_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end

    meanKitDists = squeeze(mean(kitDists, 'omitnan'))/max(kitDists,[], 'all');
    d.kitchen_RDM.ratingRDM(idx).RDM = meanKitDists;
    d.kitchen_RDM.ratingRDM(idx).name = 'GazeDist';
    d.kitchen_RDM.ratingRDM(idx).color = [0, 0, 0]';

    save(fullfile(dataDir, 'meanKitDists.mat'), 'meanKitDists');

    if cfg.calculateMannanDist

        meanMannanKitDists = squeeze(mean(kitMannanDists, 'omitnan'))/...
            max(kitMannanDists,[], 'all');

        d.kitchen_RDM.ratingRDM(idx+1).RDM = meanMannanKitDists;
        d.kitchen_RDM.ratingRDM(idx+1).name = 'MannanDist';
        d.kitchen_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

        save(fullfile(dataDir, 'meanMannanKitDists.mat'), 'meanMannanKitDists');

    end

    if strcmp(cfg.exp_name, 'combined')

        [d.compareExps.kitchen.GazeDist.res] = compare_experiments_is_rdms(...
            meanKitDists, cfg.n_permutations, 'GazeDist');

        if cfg.calculateMannanDist
            [d.compareExps.kitchen.MannanDist.res] = compare_experiments_is_rdms(...
                meanMannanKitDists, cfg.n_permutations, 'MannanDist');
        end

    end

    % bathroom
    if isfield(d, "bathroom_RDM")
        idx = length({d.bathroom_RDM.ratingRDM.RDM}) + 1;
    else
        idx = 1;
    end

    meanBatDists = squeeze(mean(bathDists, 'omitnan'))/max(bathDists,[], 'all');
    d.bathroom_RDM.ratingRDM(idx).RDM = meanBatDists;
    d.bathroom_RDM.ratingRDM(idx).name = 'GazeDist';
    d.bathroom_RDM.ratingRDM(idx).color = [0, 0, 0]';

    save(fullfile(dataDir, 'meanBatDists.mat'), 'meanBatDists');

    if cfg.calculateMannanDist

        meanMannanBatDists = squeeze(mean(bathMannanDists, 'omitnan'))/...
            max(bathMannanDists,[], 'all');

        d.bathroom_RDM.ratingRDM(idx+1).RDM = meanMannanBatDists;
        d.bathroom_RDM.ratingRDM(idx+1).name = 'MannanDist';
        d.bathroom_RDM.ratingRDM(idx+1).color = [0, 0, 0]';

        save(fullfile(dataDir, 'meanMannanBatDists.mat'), 'meanMannanBatDists');

    end

    if strcmp(cfg.exp_name, 'combined')

        [d.compareExps.bathroom.GazeDist.res] = compare_experiments_is_rdms(...
            meanBatDists, cfg.n_permutations, 'GazeDist');

        if cfg.calculateMannanDist
            [d.compareExps.bathroom.MannanDist.res] = compare_experiments_is_rdms(...
                meanMannanBatDists, cfg.n_permutations, 'MannanDist');
        end

    end

    %% split odd and even

    % bathroom
    oddBatDist = bathDists(1:2:size(bathDists,1),:,:);
    meanOddBatDists = squeeze(mean(oddBatDist,'omitnan'))/max(bathDists,[],'all');

    d.bathroom_RDM.ratingRDM(idx+2).RDM = meanOddBatDists;
    d.bathroom_RDM.ratingRDM(idx+2).name = 'meanOddBatDists';
    d.bathroom_RDM.ratingRDM(idx+2).color = [0,0,0]';

    save(fullfile(dataDir,'meanOddBatDists.mat'),'meanOddBatDists');

    evenBatDist = bathDists(2:2:size(bathDists,1),:,:);
    meanEvenBatDists = squeeze(mean(evenBatDist,'omitnan'))/max(bathDists,[],'all');

    d.bathroom_RDM.ratingRDM(idx+3).RDM = meanEvenBatDists;
    d.bathroom_RDM.ratingRDM(idx+3).name = 'meanEvenBatDists';
    d.bathroom_RDM.ratingRDM(idx+3).color = [0,0,0]';

    save(fullfile(dataDir,'meanEvenBatDists.mat'),'meanEvenBatDists');

    % Mannan Distance:
    if cfg.calculateMannanDist
        oddBatMannanDist = bathMannanDists(1:2:size(bathMannanDists,1),:,:);
        meanOddBatMannanDists = squeeze(mean(oddBatMannanDist,'omitnan'))/max(bathMannanDists,[],'all');

        d.bathroom_RDM.ratingRDM(idx+4).RDM = meanOddBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+4).name = 'meanOddBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+4).color = [0,0,0]';

        save(fullfile(dataDir,'meanOddBatMannanDists.mat'),'meanOddBatMannanDists');

        evenBatMannanDist = bathMannanDists(2:2:size(bathMannanDists,1),:,:);
        meanEvenBatMannanDists = squeeze(mean(evenBatMannanDist,'omitnan'))/max(bathMannanDists,[],'all');

        d.bathroom_RDM.ratingRDM(idx+5).RDM = meanEvenBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+5).name = 'meanEvenBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+5).color = [0,0,0]';

        save(fullfile(dataDir,'meanEvenBatMannanDists.mat'),'meanEvenBatMannanDists');
    end

    % kitchen
    oddKitDist = kitDists(1:2:size(kitDists,1),:,:);
    meanOddKitDists = squeeze(mean(oddKitDist,'omitnan'))/max(kitDists,[],'all');

    d.kitchen_RDM.ratingRDM(idx+2).RDM = meanOddKitDists;
    d.kitchen_RDM.ratingRDM(idx+2).name = 'meanOddKitDists';
    d.kitchen_RDM.ratingRDM(idx+2).color = [0,0,0]';

    save(fullfile(dataDir,'meanOddKitDists.mat'),'meanOddKitDists');

    evenKitDist = kitDists(2:2:size(kitDists,1),:,:);
    meanEvenKitDists = squeeze(mean(evenKitDist,'omitnan'))/max(kitDists,[],'all');

    d.kitchen_RDM.ratingRDM(idx+3).RDM = meanEvenKitDists;
    d.kitchen_RDM.ratingRDM(idx+3).name = 'meanEvenKitDists';
    d.kitchen_RDM.ratingRDM(idx+3).color = [0,0,0]';

    save(fullfile(dataDir,'meanEvenKitDists.mat'),'meanEvenKitDists');

    % Mannan Distance:
    if cfg.calculateMannanDist

        oddKitMannanDist = kitMannanDists(1:2:size(kitMannanDists,1),:,:);
        meanOddKitMannanDists = squeeze(mean(oddKitMannanDist,'omitnan'))/max(kitMannanDists,[],'all');

        d.kitchen_RDM.ratingRDM(idx+4).RDM = meanOddKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+4).name = 'meanOddKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+4).color = [0,0,0]';

        save(fullfile(dataDir,'meanOddKitMannanDists.mat'),'meanOddKitMannanDists');

        evenKitMannanDist = kitMannanDists(2:2:size(kitMannanDists,1),:,:);
        meanEvenKitMannanDists = squeeze(mean(evenKitMannanDist,'omitnan'))/max(kitMannanDists,[],'all');

        d.kitchen_RDM.ratingRDM(idx+5).RDM = meanEvenKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+5).name = 'meanEvenKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+5).color = [0,0,0]';

        save(fullfile(dataDir,'meanEvenKitMannanDists.mat'),'meanEvenKitMannanDists');
    end

    %% split late and early

    % bathroom
    lateBatDist = bathDists((size(bathDists,1)/2)+1:end, :, :);
    meanLateBatDists = squeeze(mean(lateBatDist,'omitnan'))/max(bathDists,[],'all');

    d.bathroom_RDM.ratingRDM(idx+2).RDM = meanLateBatDists;
    d.bathroom_RDM.ratingRDM(idx+2).name = 'meanLateBatDists';
    d.bathroom_RDM.ratingRDM(idx+2).color = [0,0,0]';

    save(fullfile(dataDir,'meanLateBatDists.mat'),'meanLateBatDists');

    earlyBatDist = bathDists(1:(size(bathDists,1)/2), :, :);
    meanEarlyBatDists = squeeze(mean(earlyBatDist,'omitnan'))/max(bathDists,[],'all');

    d.bathroom_RDM.ratingRDM(idx+3).RDM = meanEarlyBatDists;
    d.bathroom_RDM.ratingRDM(idx+3).name = 'meanEarlyBatDists';
    d.bathroom_RDM.ratingRDM(idx+3).color = [0,0,0]';

    save(fullfile(dataDir,'meanEarlyBatDists.mat'),'meanEarlyBatDists');

    % Mannan Distance:
    if cfg.calculateMannanDist
        lateBatMannanDist = bathMannanDists((size(bathDists,1)/2)+1:end, :, :);
        meanLateBatMannanDists = squeeze(mean(lateBatMannanDist,'omitnan'))/max(bathMannanDists,[],'all');

        d.bathroom_RDM.ratingRDM(idx+4).RDM = meanLateBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+4).name = 'meanLateBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+4).color = [0,0,0]';

        save(fullfile(dataDir,'meanLateBatMannanDists.mat'),'meanLateBatMannanDists');

        earlyBatMannanDist = bathMannanDists(1:(size(bathDists,1)/2), :, :);
        meanEarlyBatMannanDists = squeeze(mean(earlyBatMannanDist,'omitnan'))/max(bathMannanDists,[],'all');

        d.bathroom_RDM.ratingRDM(idx+5).RDM = meanEarlyBatMannanDists;
        d.bathroom_RDM.ratingRDM(idx+5).name = 'meanEarlyBatMannanDists';
        d.bathroom_RDM.ratingRDM(idx+5).color = [0,0,0]';

        save(fullfile(dataDir,'meanEarlyBatMannanDists.mat'),'meanEarlyBatMannanDists');
    end

    % kitchen
    lateKitDist = kitDists((size(bathDists,1)/2)+1:end,:,:);
    meanLateKitDists = squeeze(mean(lateKitDist,'omitnan'))/max(kitDists,[],'all');

    d.kitchen_RDM.ratingRDM(idx+2).RDM = meanLateKitDists;
    d.kitchen_RDM.ratingRDM(idx+2).name = 'meanLateKitDists';
    d.kitchen_RDM.ratingRDM(idx+2).color = [0,0,0]';

    save(fullfile(dataDir,'meanLateKitDists.mat'),'meanLateKitDists');

    earlyKitDist = kitDists(21:(size(bathDists,1)/2), :, :);
    meanEarlyKitDists = squeeze(mean(earlyKitDist,'omitnan'))/max(kitDists,[],'all');

    d.kitchen_RDM.ratingRDM(idx+3).RDM = meanEarlyKitDists;
    d.kitchen_RDM.ratingRDM(idx+3).name = 'meanEarlyKitDists';
    d.kitchen_RDM.ratingRDM(idx+3).color = [0,0,0]';

    save(fullfile(dataDir,'meanEarlyKitDists.mat'),'meanEarlyKitDists');

    % Mannan Distance:
    if cfg.calculateMannanDist

        lateKitMannanDist = kitMannanDists((size(bathDists,1)/2)+1:end, :, :);
        meanLateKitMannanDists = squeeze(mean(lateKitMannanDist,'omitnan'))/max(kitMannanDists,[],'all');

        d.kitchen_RDM.ratingRDM(idx+4).RDM = meanLateKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+4).name = 'meanLateKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+4).color = [0,0,0]';

        save(fullfile(dataDir,'meanLateKitMannanDists.mat'),'meanLateKitMannanDists');

        earlyKitMannanDist = kitMannanDists(1:(size(bathDists,1)/2), :, :);
        meanEarlyKitMannanDists = squeeze(mean(earlyKitMannanDist,'omitnan'))/max(kitMannanDists,[],'all');

        d.kitchen_RDM.ratingRDM(idx+5).RDM = meanEarlyKitMannanDists;
        d.kitchen_RDM.ratingRDM(idx+5).name = 'meanEarlyKitMannanDists';
        d.kitchen_RDM.ratingRDM(idx+5).color = [0,0,0]';

        save(fullfile(dataDir,'meanEarlyKitMannanDists.mat'),'meanEarlyKitMannanDists');
    end
end

%% comapre bewteen categories
pwc_idx = height(d.RDM_pwc_table);
d.RDM_pwc_table.task(idx + 1) = "Gaze dist";
[d.RDM_pwc_table.r(idx + 1), d.RDM_pwc_table.p(idx + 1)] =...
    corr(squareform(meanBatDists)', squareform(meanKitDists)');

d.RDM_pwc_table.task(idx + 2) = "Mannan dist";
[d.RDM_pwc_table.r(idx + 2), d.RDM_pwc_table.p(idx + 2)] =...
    corr(squareform(meanMannanBatDists)', squareform(meanMannanKitDists)');


end