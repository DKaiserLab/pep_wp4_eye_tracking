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

%Note, some fixations fall in between mutiple objects. The variable 'LabeledFix.(category).ObjectDwellsMulti'
%takes this into account whereas 'LabeledFix.(category).ObjectDwells' does not.
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
    LabeledFix.(category).ObjectFixCount = zeros(n, height(log_file));

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
    LabeledFix.(category).category_file = category_file;

    %% 3. gather individual dwell times

    for iSubj = 1:n

        % run time control
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
        LabeledFix.(category).ObjectDwellsMulti(iSubj,:)  = zeros(1, NumObjsTotal);
        LabeledFix.(category).ObjectMultiFixated(iSubj,:) = zeros(1, NumObjsTotal);
        LabeledFix.(category).isOdd(iSubj,:) = logical(zeros(1, NumObjsTotal));
        LabeledFix.(category).ObjectDwellsMultiCate(iSubj,:) = zeros(1, height(category_file));
        LabeledFix.(category).ObjectDwellsMultiCateOdd(iSubj,:) = zeros(1, height(category_file));
        LabeledFix.(category).ObjectDwellsMultiCateEven(iSubj,:) = zeros(1, height(category_file));


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
                LabeledFix.(category).ObjectDwellTotal(iSubj,iImg) = fix_data.duration(1);
                for ifix = 1:height(fix_data)
                    if ifix > 1
                        if fix_data.fixNr(ifix) ~= fix_data.fixNr(ifix-1)
                            LabeledFix.(category).ObjectDwellTotal(iSubj,iImg) = ...
                                LabeledFix.(category).ObjectDwellTotal(iSubj,iImg) + fix_data.duration(ifix);
                        end
                    end
                end
            end

            ObjCountinit = ObjCount + 1;
            for iObjs = 1:height(ObjsInImg)
                ObjCount = ObjCount + 1;

                fix_data_obj = fix_data(fix_data.AOINr == iObjs,:);

                if ~isempty(fix_data_obj) %if the current object was indeed fixated (otherwise it will be skipped and the zero (no dwell time) will remain)

                    % sum over duration were the current object was fixated
                    % and divide by total duration of all fixations
                    LabeledFix.(category).ObjectDwellsMulti(iSubj,ObjCount)  = ...
                        nansum(fix_data_obj.duration)/LabeledFix.(category).ObjectDwellTotal(iSubj,iImg);
                    LabeledFix.(category).ObjectMultiFixated(iSubj,ObjCount) = 1;


                    % check which category the stimulus belongs to
                    [~,obj_name,~] = fileparts(ObjsInImg(iObjs).name);
                    obj_idx = strcmp(table2cell(category_file), obj_name);

                    % if part of a category
                    if sum(sum(obj_idx)) > 0
                        cate_num = find(sum(obj_idx, 2));

                        % add dwell time to category
                        LabeledFix.(category).ObjectDwellsMultiCate(iSubj,cate_num) = ...
                            LabeledFix.(category).ObjectDwellsMultiCate(iSubj,cate_num)...
                            + sum(fix_data_obj.duration)/LabeledFix.(category).ObjectDwellTotal(iSubj,iImg);

                        % add dwell time to category seperate for odd and even trials
                        if isOdd
                            LabeledFix.(category).ObjectDwellsMultiCateOdd(iSubj,cate_num) = ...
                                LabeledFix.(category).ObjectDwellsMultiCateOdd(iSubj,cate_num)...
                                + sum(fix_data_obj.duration)/LabeledFix.(category).ObjectDwellTotal(iSubj,iImg);
                        else
                            LabeledFix.(category).ObjectDwellsMultiCateEven(iSubj,cate_num) = ...
                                LabeledFix.(category).ObjectDwellsMultiCateEven(iSubj,cate_num)...
                                + sum(fix_data_obj.duration)/LabeledFix.(category).ObjectDwellTotal(iSubj,iImg);
                        end
                    end
                end
                %end
            end %iObjs

            %sum how many objects have been fixated by the participant in
            %the current image
            if ~any(isnan(LabeledFix.(category).ObjectMultiFixated(iSubj,ObjCountinit:ObjCount)))
                LabeledFix.(category).ObjectFixCount(iSubj,iImg) = ...
                    sum(LabeledFix.(category).ObjectDwellsMulti(iSubj,ObjCountinit:ObjCount)~= 0); %sum how many objects were fixated
            end

            % mark odd trials
            if isOdd
                LabeledFix.(category).isOdd(iSubj,ObjCountinit:ObjCount) = true;
            else
                LabeledFix.(category).isOdd(iSubj,ObjCountinit:ObjCount) = false;
            end

            %write data in struct
            LabeledFix.(category).Data{iImg,iSubj} = fix_data;
        end % images
    end % subjects

    %% 4. calculate pairwise comparisons between individuals,
    %producing an Gaze Dissimilarity Matrix (GDM) by using spearman
    %correlations
    [ObserverMatObjects, ~] = corr(LabeledFix.(category).ObjectDwellsMulti',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatObjectCategories, ~] = corr(LabeledFix.(category).ObjectDwellsMultiCate',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatObjectsFix, ~] = corr(LabeledFix.(category).ObjectMultiFixated', 'type',...
        'spearman', 'rows', 'complete');

    

end

% write to data structure
d.GDM = LabeledFix;
end