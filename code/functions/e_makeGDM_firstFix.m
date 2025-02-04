function d = e_makeGDM_firstFix(d, cfg)

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

    %% 3. gather individual first fixes

    for iSubj = 1:n

        % run time control
        disp(['Evaluating subject ', subs{iSubj}])

        FixData_dir = fullfile(pwd, '..', 'derivatives', ['sub-', subs{iSubj}], 'AOIfix');
        if ~isfolder(FixData_dir)
            disp(['Missing AOI fixation data for: ', subs{iSubj}]);
        end

        % get current trials
        all_trials = dir(fullfile(FixData_dir,'sub-*'));
        category_trials = all_trials(isCurrentCategory);
        category_idx = find(isCurrentCategory);

        % init data structures
        LabeledFix.(category).Objects_firstFix(iSubj,:)  = zeros(1, NumObjsTotal);
        LabeledFix.(category).isOdd_firstFix(iSubj,:) = logical(zeros(1, NumObjsTotal));
        LabeledFix.(category).ObjectsCate_firstFix(iSubj,:) = zeros(1, height(category_file));
        LabeledFix.(category).ObjectsCate_firstFixOdd(iSubj,:) = zeros(1, height(category_file));
        LabeledFix.(category).ObjectsCate_firstFixEven(iSubj,:) = zeros(1, height(category_file));

        % get mat file for subject
        matFile = fullfile('..','sourcedata', ['sub-', subs{iSubj}], ['sub-', subs{iSubj} '_task-EyeTracking_physio']); % directory where subject mat files are placed
        sess = load(matFile,'expt');

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

            
            % Calculate pixels per degree of visual angle 
            visual_angle_height = 15;
            coords = sess.expt.stim(iImg).scrRect;
            height_pixels = coords(4) - coords(2);  % bottom - top
            pixels_per_degree = height_pixels / visual_angle_height;

            % get center of the image
            centerX = sess.expt.resolution(1) / 2;
            centerY = sess.expt.resolution(2) / 2;

            % calculate distance to center for each fixation
            fix_data.dist2center = zeros(height(fix_data), 1);
            fix_data.notCenter = zeros(height(fix_data), 1);
            for rows = 1:height(fix_data)
                fix_data.dist2center(rows) = sqrt((fix_data.X_pix_(rows) -...
                    centerX)^2 + (fix_data.Y_pix_(rows) - centerY)^2);
            end

            % select first fixation more than 0.5 degrees of visual angle away
            % from center 
            notCenter = fix_data.dist2center > pixels_per_degree/2;
            fix_data = fix_data(notCenter, :);
            first_fix_data = fix_data(fix_data.fixNr == min(fix_data.fixNr), :);

            ObjCountinit = ObjCount + 1;
            for iObjs = 1:height(ObjsInImg)
                ObjCount = ObjCount + 1;

                fix_data_obj = first_fix_data(first_fix_data.AOINr == iObjs,:);

                if ~isempty(fix_data_obj) %if the current object was indeed fixated (otherwise it will be skipped and the zero (no dwell time) will remain)

                    % add 1 if object in first fixation
                    LabeledFix.(category).Objects_firstFix(iSubj, ObjCount) = 1;

                    % check which category the stimulus belongs to
                    [~,obj_name,~] = fileparts(ObjsInImg(iObjs).name);
                    obj_idx = strcmp(table2cell(category_file), obj_name);

                    % if part of a category
                    if sum(sum(obj_idx)) > 0
                        cate_num = find(sum(obj_idx, 2));

                        % add 1 to category value
                        LabeledFix.(category).ObjectsCate_firstFix(iSubj, cate_num) = ...
                            LabeledFix.(category).ObjectsCate_firstFix(iSubj, cate_num) + 1;

                        % add 1 to category seperate for odd and even trials
                        if isOdd
                        LabeledFix.(category).ObjectsCate_firstFixOdd(iSubj, cate_num) = ...
                            LabeledFix.(category).ObjectsCate_firstFixOdd(iSubj, cate_num) + 1;
                        else
                        LabeledFix.(category).ObjectsCate_firstFixEven(iSubj, cate_num) = ...
                            LabeledFix.(category).ObjectsCate_firstFixEven(iSubj, cate_num) + 1;
                        end
                    end
                end
            end %iObjs

            % mark odd trials
            if isOdd
                LabeledFix.(category).isOdd_firstFix(iSubj,ObjCountinit:ObjCount) = true;
            else
                LabeledFix.(category).isOdd_firstFix(iSubj,ObjCountinit:ObjCount) = false;
            end

            %write data in struct
            LabeledFix.(category).Data_firstFix{iImg,iSubj} = first_fix_data;
        end % images
    end % subjects

    %     %% 4. calculate pairwise comparisons between individuals,
    %     %producing an Gaze Dissimilarity Matrix (GDM) by using spearman
    %     %correlations
    %     [ObserverMatObjects, ~] = corr(LabeledFix.(category).ObjectDwellsMulti',...
    %         'type', 'spearman', 'rows', 'complete');
    %     [ObserverMatObjectCategories, ~] = corr(LabeledFix.(category).ObjectDwellsMultiCate',...
    %         'type', 'spearman', 'rows', 'complete');
    %     [ObserverMatObjectsFix, ~] = corr(LabeledFix.(category).ObjectMultiFixated', 'type',...
    %         'spearman', 'rows', 'complete');

    %% 5. split-half reliablity - single object dwell time

    % runtime control
    disp(' ')
    disp(['Split-half reliablity for ', category, ' images on first fixation'])

    [ObserverMatOdd, ~] = corr(LabeledFix.(category).Objects_firstFix(:,LabeledFix.(category).isOdd_firstFix(1,:))',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEven, ~] = corr(LabeledFix.(category).Objects_firstFix(:,~LabeledFix.(category).isOdd_firstFix(1,:))',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOdd(logical(eye(size(ObserverMatOdd)))) = 0;
    [C] = squareform(ObserverMatOdd);
    % even
    ObserverMatEven(logical(eye(size(ObserverMatEven)))) = 0;
    [D] = squareform(ObserverMatEven);

    % print correlation
    disp(' ')
    disp('Single object first fixation')
    [R, p] = corr(C', D');
    disp(['pearson r: ' num2str(R) ', p = ' num2str(p)]);
    [R, p] = corr(C', D','Type','Spearman');
    disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);


    % for category: %6. split-half reliablity
    [ObserverMatOddCate, ~] = corr(LabeledFix.(category).ObjectsCate_firstFixOdd',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEvenCate, ~] = corr(LabeledFix.(category).ObjectsCate_firstFixEven',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOddCate(logical(eye(size(ObserverMatOddCate)))) = 0;
    [E] = squareform(ObserverMatOddCate);
    % even
    ObserverMatEvenCate(logical(eye(size(ObserverMatEvenCate)))) = 0;
    [F] = squareform(ObserverMatEvenCate);

    % print correlation
    disp(' ')
    disp('Category first fixation count')
    [R, p] = corr(E', F');
    disp(['pearson r: ' num2str(R) ', p = ' num2str(p)]);
    [R, p] = corr(E', F','Type','Spearman');
    disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);


    % write to data structure
    field_names = fieldnames(LabeledFix.(category));
    for field = 1:length(field_names)
        field_name = char(field_names{field});
        d.GDM.(category).(field_name) = LabeledFix.(category).(field_name);
    end

end
end 