function d = e_makeGDM(d, cfg)

%This script is adapted from Kollenda and de Haas 2024 (https://osf.io/83mjc/)
%It produces the Gaze Dissimilarity Matrix (GDM)
%--> how similar are the dwell time distributions across objects are
%between a given pair of observers?

%script:
%1. creates a matrix with one row per observer and one column for each object
%   in the image set (there are several hundreds across all 100 images).
%2. Initializes all entries to zero and
%3. gathers the individual dwell time for each object and observer.
%4. calculates euclidean distances dwell time distributions between
%   pairs of observer.
%5. performs a consistency check.

%Note, some fixations fall in between mutiple objects. The variable 'ObjectDwellsMulti'
%takes this into account whereas 'ObjectDwells' does not.
%In the manuscript we only report results that consider
%ObjectDwellsMulti.



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
categories = {'bathroom', 'kitchen'};
for iCate = 1:length(categories)

    % get category
    category = categories{iCate};

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
    category_file = category_file;

    %% 3. gather individual dwell times

    for iSubj = 1:n

        % check if subject data exists
        subDir = fullfile(pwd, '..', 'derivatives',  ['sub-', subs{1}], 'gazePatterns');
        if exist(subDir, 'dir')
            % check if all files exist
            allExist = exist(fullfile(subDir, category, 'ObjectDwellsMulti.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectMultiFixated.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file') ||...
                exist(fullfile(subDir, category, 'ObjectDwellsMultiCate.mat'), 'file');


        else
            % run time control
            mkdir(subDir)
            disp(['Evaluating subject ',subs{iSubj}])
        end

        FixData_dir = fullfile(pwd, '..', 'derivatives', ['sub-', subs{iSubj}], 'AOIfix');
        if ~isfolder(FixData_dir)
            disp(['Missing AOI fixation data for: ',subs{iSubj}]);
        end

        % get current trials
        all_trials = dir(fullfile(FixData_dir,'sub-*'));
        category_trials = all_trials(isCurrentCategory);
        category_idx = find(isCurrentCategory);

        % init data structures
        ObjectDwellsMulti(iSubj,:)  = zeros(1, NumObjsTotal);
        ObjectMultiFixated(iSubj,:) = zeros(1, NumObjsTotal);
        isOdd(iSubj,:) = logical(zeros(1, NumObjsTotal));
        ObjectDwellsMultiCate(iSubj,:) = zeros(1, height(category_file));
        ObjectDwellsMultiCateOdd(iSubj,:) = zeros(1, height(category_file));
        ObjectDwellsMultiCateEven(iSubj,:) = zeros(1, height(category_file));
        ObjectCatePrio(iSubj,:) = nan(1, height(category_file));
        ObjectCatePrioOdd(iSubj,:) = nan(1, height(category_file));
        ObjectCatePrioEven(iSubj,:) = nan(1, height(category_file));
        timeToFixMat = nan(height(category_trials), height(category_file));

        ObjCount = 0;
        ObjEven  = [];
        ObjOdd   = [];
        for iImg = 1:height(category_trials)

            % get objects in image
            image_name = char(log_file.image(category_idx(iImg)));
            ObjsInImg = dir(fullfile('..','AOIs',char(image_name),'*.png'));

            % check whether image is odd
            if mod(iImg, 2) == 1; isOdd = true; else; isOdd = false; end

            % get AOI fix data for image and participant
            warning off
            fix_data = readtable(fullfile(category_trials(iImg).folder,category_trials(iImg).name),...
                'FileType', 'text', 'Delimiter', '\t');
            warning on

            % get sum of all fixations
            if height(fix_data) > 0
                ObjectDwellTotal(iSubj,iImg) = fix_data.duration(1);
                for ifix = 1:height(fix_data)
                    if ifix > 1
                        if fix_data.fixNr(ifix) ~= fix_data.fixNr(ifix-1)
                            ObjectDwellTotal(iSubj,iImg) = ...
                                ObjectDwellTotal(iSubj,iImg) + fix_data.duration(ifix);
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
                    ObjectDwellsMulti(iSubj,ObjCount)  = ...
                        nansum(fix_data_obj.duration)/ObjectDwellTotal(iSubj,iImg);
                    ObjectMultiFixated(iSubj,ObjCount) = 1;

                    % if part of a category
                    if sum(sum(obj_idx)) > 0
                        cate_num = find(sum(obj_idx, 2));

                        % add dwell time to category
                        ObjectDwellsMultiCate(iSubj,cate_num) = ...
                            ObjectDwellsMultiCate(iSubj,cate_num)...
                            + sum(fix_data_obj.duration)/ObjectDwellTotal(iSubj,iImg);

                        % add dwell time to category seperate for odd and even trials
                        if isOdd
                            ObjectDwellsMultiCateOdd(iSubj,cate_num) = ...
                                ObjectDwellsMultiCateOdd(iSubj,cate_num)...
                                + sum(fix_data_obj.duration)/ObjectDwellTotal(iSubj,iImg);
                        else
                            ObjectDwellsMultiCateEven(iSubj,cate_num) = ...
                                ObjectDwellsMultiCateEven(iSubj,cate_num)...
                                + sum(fix_data_obj.duration)/ObjectDwellTotal(iSubj,iImg);
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
            if ~any(isnan(ObjectMultiFixated(iSubj,ObjCountinit:ObjCount)))
                ObjectFixCount(iSubj,iImg) = ...
                    sum(ObjectDwellsMulti(iSubj,ObjCountinit:ObjCount)~= 0); %sum how many objects were fixated
            end

            % mark odd trials
            if isOdd
                isOdd(iSubj,ObjCountinit:ObjCount) = true;
            else
                isOdd(iSubj,ObjCountinit:ObjCount) = false;
            end

            %write data in struct
            Data{iImg,iSubj} = fix_data;
        end % images

        % average time to fixation (= fixation priority)
        ObjectCatePrio(iSubj,:) = mean(timeToFixMat, 'omitnan');
        oddTrialsTimeToFixMat = timeToFixMat(1:2:height(timeToFixMat), :);
        ObjectCatePrioOdd(iSubj,:) = mean(oddTrialsTimeToFixMat, 'omitnan');
        evenTrialsTimeToFixMat = timeToFixMat(2:2:height(timeToFixMat), :);
        ObjectCatePrioEven(iSubj,:) = mean(evenTrialsTimeToFixMat, 'omitnan');

        % save subject data 


    end % subjects
end
end