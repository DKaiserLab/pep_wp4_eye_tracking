function e_getGazePatterns(cfg)

%% 2. initialize
% define subjets

subs = [];
for sub = 1:numel(cfg.subNums)
    subs = [subs, {sprintf('%0.3d', cfg.subNums(sub))}];
end
n = length(subs);

% get log file
log_file = readtable(fullfile(pwd, '..', 'sourcedata', ['sub-', subs{1}],...
    ['sub-', subs{1}, '_task-EyeTracking_events.tsv']),'FileType', 'text', 'Delimiter', '\t');
log_file = log_file(log_file.trial > 0,:);

% get category membership of images
imageCategoriesFile = fullfile(pwd, '..', 'imageCategories.csv');
imageCategories = readtable(imageCategoriesFile,'Format','auto');

% loop through categories
for iCate = 1:length(cfg.categories)
    % get category
    category = cfg.categories{iCate};

    % init data struct
    ObjectFixCount = zeros(n, height(log_file));

    % get total number of objects
    NumObjsTotal = 0;
    isCurrentCategory = logical(zeros(1, length(log_file.image(:)')));
    for iTrial = 1:length(log_file.image(:))
        img_name = char(log_file.image(iTrial));

        % get category of the image
        currentImageCategory = imageCategories{strcmp(imageCategories{:,1},img_name),2};

        % check if images belongs to current category
        if strcmp(currentImageCategory, category)
            isCurrentCategory(iTrial) = true;

            % get all object in that image
            object_masks = dir(fullfile('..','AOIs', img_name, '*.png'));
            % increase couter
            NumObjsTotal = NumObjsTotal + numel(object_masks);
        end
    end

    % get category memberships
    category_file_all = readtable(fullfile(pwd, '..', 'objectCategories.xlsx'),'Format','auto');
    category_file = category_file_all(category_file_all.([category, 'Frequency']) >= 10, :);

    %% 3. gather individual dwell times
    for iSubj = 1:n

        % check if subject data exists
        outputDir = fullfile(pwd, '..', 'derivatives',  ['sub-', subs{iSubj}], 'gazePatterns', category);
        if exist(outputDir, 'dir')
            % check if all files exist
            allExist = exist(fullfile(outputDir, 'ObjectFixCount.mat'), 'file') ||...
                exist(fullfile(outputDir, 'IndividualObjectDwells.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectFixated.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectDwellsCate.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectDwellsCateOdd.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectDwellsCateEven.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectCatePrio.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectCatePrioOdd.mat'), 'file') ||...
                exist(fullfile(outputDir, 'ObjectCatePrioEven.mat'), 'file');
            if allExist
                disp(['Subject ',subs{iSubj}, ' already exists'])
                continue
            end 
        else
            % run time control
            mkdir(outputDir)
        end
        disp(['Evaluating subject ',subs{iSubj}])

        FixData_dir = fullfile(pwd, '..', 'derivatives', ['sub-', subs{iSubj}], 'AOIfix');
        if ~isfolder(FixData_dir)
            disp(['Missing AOI fixation data for: ',subs{iSubj}]);
        end

        % get current trials
        all_trials = dir(fullfile(FixData_dir,'sub-*'));
        category_trials = all_trials(isCurrentCategory);
        category_idx = find(isCurrentCategory);

        % init data structures
        ObjectFixCount = zeros(1, height(category_trials));
        IndividualObjectDwells  = zeros(1, NumObjsTotal);
        ObjectFixated = zeros(1, NumObjsTotal);
        isOdd = logical(zeros(1, NumObjsTotal));
        ObjectDwellsCate = zeros(1, height(category_file));
        ObjectDwellsCateOdd = zeros(1, height(category_file));
        ObjectDwellsCateEven = zeros(1, height(category_file));
        timeToFixMat = nan(height(category_trials), height(category_file));

        ObjCount = 0;
        ObjEven  = [];
        ObjOdd   = [];
        for iImg = 1:height(category_trials)

            % get objects in image
            image_name = char(log_file.image(category_idx(iImg)));
            ObjsInImg = dir(fullfile('..','AOIs',char(image_name),'*.png'));

            % check whether image is odd
            if mod(iImg, 2) == 1; isCurrentOdd = true; else; isCurrentOdd = false; end

            % get AOI fix data for image and participant
            warning off
            fix_data = readtable(fullfile(category_trials(iImg).folder,category_trials(iImg).name),...
                'FileType', 'text', 'Delimiter', '\t');
            warning on

            % get sum of all fixations
            ObjectDwellTotal = nan(1, height(fix_data));
            if height(fix_data) > 0
                ObjectDwellTotal(iImg) = fix_data.duration(1);
                for ifix = 1:height(fix_data)
                    if ifix > 1
                        if fix_data.fixNr(ifix) ~= fix_data.fixNr(ifix-1)
                            ObjectDwellTotal(iImg) = ...
                                ObjectDwellTotal(iImg) + fix_data.duration(ifix);
                        end
                    end
                end
            end

            ObjCountinit = ObjCount + 1;
            for iObjs = 1:height(ObjsInImg)
                ObjCount = ObjCount + 1;

                % check which category the stimulus belongs to
                [~,obj_name,~] = fileparts(ObjsInImg(iObjs).name);
                obj_idx = strcmp(table2cell(category_file), obj_name);

                % get fixation with current object (if any)
                fix_data_obj = fix_data(fix_data.AOINr == iObjs,:);

                if ~isempty(fix_data_obj) %if the current object was indeed fixated (otherwise it will be skipped and the zero (no dwell time) will remain)

                    % sum over duration were the current object was fixated
                    % and divide by total duration of all fixations
                    IndividualObjectDwells(ObjCount)  = ...
                        nansum(fix_data_obj.duration)/ObjectDwellTotal(iImg);
                    ObjectFixated(ObjCount) = 1;

                    % if part of a category
                    if sum(sum(obj_idx)) > 0
                        cate_num = find(sum(obj_idx, 2));

                        % add dwell time to category
                        ObjectDwellsCate(cate_num) = ...
                            ObjectDwellsCate(cate_num)...
                            + sum(fix_data_obj.duration)/ObjectDwellTotal(iImg);

                        % add dwell time to category seperate for odd and even trials
                        if isCurrentOdd
                            ObjectDwellsCateOdd(cate_num) = ...
                                ObjectDwellsCateOdd(cate_num)...
                                + sum(fix_data_obj.duration)/ObjectDwellTotal(iImg);
                        else
                            ObjectDwellsCateEven(cate_num) = ...
                                ObjectDwellsCateEven(cate_num)...
                                + sum(fix_data_obj.duration)/ObjectDwellTotal(iImg);
                        end

                        % get time when object category was fixated first
                        firstCateFix = fix_data_obj.startT(1);
                        if isnan(timeToFixMat(iImg, cate_num(1)))
                            timeToFixMat(iImg, cate_num(1)) = firstCateFix;
                        else
                            if firstCateFix < timeToFixMat(iImg, cate_num(1))
                                timeToFixMat(iImg, cate_num(1)) = firstCateFix;
                            end
                        end
                    end
                else
                    % if object was not looked it time to fixation =
                    % trial length (3s)
                    if sum(sum(obj_idx)) > 0
                        cate_num = find(sum(obj_idx, 2));
                        timeToFixMat(iImg, cate_num(1)) = 3;
                    end
                end
            end %iObjs

            %sum how many objects have been fixated by the participant in
            %the current image
            if ~any(isnan(ObjectFixated(ObjCountinit:ObjCount)))
                ObjectFixCount(iImg) = ...
                    sum(IndividualObjectDwells(ObjCountinit:ObjCount)~= 0); %sum how many objects were fixated
            end

            % mark odd trials
            if isCurrentOdd
                isOdd(ObjCountinit:ObjCount) = true;
            else
                isOdd(ObjCountinit:ObjCount) = false;
            end

            %write data in struct
            Data{iImg} = fix_data;
        end % images

        % average time to fixation (= fixation priority)
        ObjectCatePrio = mean(timeToFixMat, 'omitnan');
        oddTrialsTimeToFixMat = timeToFixMat(1:2:height(timeToFixMat), :);
        ObjectCatePrioOdd = mean(oddTrialsTimeToFixMat, 'omitnan');
        evenTrialsTimeToFixMat = timeToFixMat(2:2:height(timeToFixMat), :);
        ObjectCatePrioEven = mean(evenTrialsTimeToFixMat, 'omitnan');

        % save subject data
        save(fullfile(outputDir, 'ObjectFixCount.mat'), 'ObjectFixCount');
        save(fullfile(outputDir, 'IndividualObjectDwells.mat'), 'IndividualObjectDwells');
        save(fullfile(outputDir, 'ObjectFixated.mat'), 'ObjectFixated');
        save(fullfile(outputDir, 'ObjectDwellsCate.mat'), 'ObjectDwellsCate');
        save(fullfile(outputDir, 'ObjectDwellsCateOdd.mat'), 'ObjectDwellsCateOdd');
        save(fullfile(outputDir, 'ObjectDwellsCateEven.mat'), 'ObjectDwellsCateEven');
        save(fullfile(outputDir, 'ObjectCatePrio.mat'), 'ObjectCatePrio');
        save(fullfile(outputDir, 'ObjectCatePrioOdd.mat'), 'ObjectCatePrioOdd');
        save(fullfile(outputDir, 'ObjectCatePrioEven.mat'), 'ObjectCatePrioEven');
        save(fullfile(outputDir, 'fixData.mat'), 'Data', 'isOdd');

    end % subjects
end
end