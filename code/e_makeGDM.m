
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

%Note, some fixations fall in between mutiple objects. The variable 'LabeledFix.ObjectDwellsMulti'
%takes this into account whereas 'LabeledFix.ObjectDwells' does not.
%In the manuscript we only report results that consider
%ObjectDwellsMulti.


clear variables; clear global; clear mex; close all; fclose('all'); clc

%2. initialize
% define subjets
subs = [];
sourcedata_folder = dir(fullfile(pwd,'..','sourcedata','sub-*'));
for n = 1:numel(sourcedata_folder)
    subs = [subs, {strrep(sourcedata_folder(n).name, 'sub-', '')}];
end

% get log file
log_file = readtable(fullfile(pwd, '..', 'sourcedata', ['sub-', subs{1}],...
    ['sub-', subs{1}, '_task-EyeTracking_events.tsv']),'FileType', 'text', 'Delimiter', '\t');
log_file = log_file(log_file.trial > 0,:);

% init data struct
LabeledFix.ObjectFixCount = zeros(n, height(log_file));

% get total number of objects
NumObjsTotal = 0;
for img_name = log_file.image(:)'
    % get all object in that image
    object_masks = dir(fullfile('..','AOIs',char(img_name),'*.png'));
    % increase couter
    NumObjsTotal = NumObjsTotal + numel(object_masks);
end

% get category memberships
category_file_all = readtable(fullfile(pwd, '..', 'category_members.xlsx'),'Format','auto');
category_file = category_file_all(category_file_all.Frequency >= 10, :);


%3. gather individual dwell times

for iSubj = 1:n
    FixData_dir = fullfile(pwd, '..', 'derivatives', ['sub-', subs{iSubj}], 'AOIfix');
    if ~isfolder(FixData_dir)
        disp(['Missing AOI fixation data for: ',subs{iSubj}]);
    end
    all_trials = dir(fullfile(FixData_dir,'sub-*'));

    % init data structures
    LabeledFix.ObjectDwellsMulti(iSubj,:)  = zeros(1, NumObjsTotal);
    LabeledFix.ObjectMultiFixated(iSubj,:) = zeros(1, NumObjsTotal);
    LabeledFix.isOdd(iSubj,:) = logical(zeros(1, NumObjsTotal));
    LabeledFix.ObjectDwellsMultiCate(iSubj,:) = zeros(1, height(category_file));
    LabeledFix.ObjectDwellsMultiCateOdd(iSubj,:) = zeros(1, height(category_file));
    LabeledFix.ObjectDwellsMultiCateEven(iSubj,:) = zeros(1, height(category_file));


    ObjCount = 0;
    ObjEven  = [];
    ObjOdd   = [];
    for iImg = 1:height(all_trials)

        % get object in image
        image_name = char(log_file.image(iImg));
        ObjsInImg = dir(fullfile('..','AOIs',char(image_name),'*.png'));

        % check whether image is odd
        if mod(iImg, 2) == 1; isOdd = true; else; isOdd = false; end

        % get AOI fix data for image and participant
        warning off
        fix_data = readtable(fullfile(all_trials(iImg).folder,all_trials(iImg).name),'FileType', 'text', 'Delimiter', '\t');
        warning on

        % get sum of all fixations
        LabeledFix.ObjectDwellTotal(iSubj,iImg) = fix_data.duration(1);
        for ifix = 1:height(fix_data)
            if ifix > 1
                if fix_data.fixNr(ifix) ~= fix_data.fixNr(ifix-1)
                    LabeledFix.ObjectDwellTotal(iSubj,iImg) = ...
                        LabeledFix.ObjectDwellTotal(iSubj,iImg) + fix_data.duration(ifix);
                end
            end
        end

        ObjCountinit = ObjCount + 1;
        for iObjs = 1:height(ObjsInImg)
            ObjCount = ObjCount + 1;

            fix_data_obj = fix_data(fix_data.AOINr == iObjs,:);

            if ~isempty(fix_data_obj) %if the current object was indeed fixated (otherwise it will be skipped and the zero (no dwell time) will remain)
                
                %sum over all the rows were the current object was fixated and sum the durations
                LabeledFix.ObjectDwellsMulti(iSubj,ObjCount)  = ...
                    nansum(fix_data_obj.duration)/LabeledFix.ObjectDwellTotal(iSubj,iImg);
                LabeledFix.ObjectMultiFixated(iSubj,ObjCount) = 1;


                % check which category the stimulus belongs to
                [~,obj_name,~] = fileparts(ObjsInImg(iObjs).name);
                obj_idx = strcmp(table2cell(category_file), obj_name);

                % if part of a category
                if sum(sum(obj_idx)) > 0 
                    cate_num = find(sum(obj_idx, 2));

                    % add dwell time to category
                    LabeledFix.ObjectDwellsMultiCate(iSubj,cate_num) = LabeledFix.ObjectDwellsMultiCate(iSubj,cate_num)...
                        + sum(fix_data_obj.duration)/LabeledFix.ObjectDwellTotal(iSubj,iImg);

                    % add dwell time to category seperate for odd and even trials
                    if isOdd
                        LabeledFix.ObjectDwellsMultiCateOdd(iSubj,cate_num) = LabeledFix.ObjectDwellsMultiCateOdd(iSubj,cate_num)...
                            + sum(fix_data_obj.duration)/LabeledFix.ObjectDwellTotal(iSubj,iImg);
                    else
                        LabeledFix.ObjectDwellsMultiCateEven(iSubj,cate_num) = LabeledFix.ObjectDwellsMultiCateEven(iSubj,cate_num)...
                            + sum(fix_data_obj.duration)/LabeledFix.ObjectDwellTotal(iSubj,iImg);
                    end
                end
            end
            %end
        end %iObjs

        %sum how many objects have been fixated by the participant in
        %the current image
        if ~any(isnan(LabeledFix.ObjectMultiFixated(iSubj,ObjCountinit:ObjCount)))
            LabeledFix.ObjectFixCount(iSubj,iImg) = sum(LabeledFix.ObjectDwellsMulti(iSubj,ObjCountinit:ObjCount)~= 0); %sum how many objects were fixated
        end
        
        % mark odd trials
        if isOdd
            LabeledFix.isOdd(iSubj,ObjCountinit:ObjCount) = true;
        else
            LabeledFix.isOdd(iSubj,ObjCountinit:ObjCount) = false;
        end
        
        %write data in struct
        LabeledFix.Data{iImg,iSubj} = fix_data; 
    end % images
end % subjects

%4. calculate pairwise comparisons between individuals,
%producing an Gaze Dissimilarity Matrix (GDM) by using spearman
%correlations
[ObserverMatObjects, ~] = corr(LabeledFix.ObjectDwellsMulti', 'type', 'spearman', 'rows', 'complete');
[ObserverMatObjectCategories, ~] = corr(LabeledFix.ObjectDwellsMultiCate', 'type', 'spearman', 'rows', 'complete');
[ObserverMatObjectsFix, ~] = corr(LabeledFix.ObjectMultiFixated', 'type', 'spearman', 'rows', 'complete');

%5. split-half reliablity - single object dwell time
[ObserverMatOdd, ~] = corr(LabeledFix.ObjectDwellsMulti(:,LabeledFix.isOdd(1,:))', 'type', 'spearman', 'rows', 'complete');
[ObserverMatEven, ~] = corr(LabeledFix.ObjectDwellsMulti(:,~LabeledFix.isOdd(1,:))', 'type', 'spearman', 'rows', 'complete');

% fs = filesep();
% CreateDissimilarityPlots(ObserverMatOdd, 'ObserverMatObjectsOdd', ['GDM:'...
%     sprintf('\n Object dwell time')], ['data' fs 'gaze' fs 'Results' fs]);
% save('data/gaze/Results/ObserverMatOdd','ObserverMatOdd')
% CreateDissimilarityPlots(ObserverMatEven, 'ObserverMatObjectsEven', ['GDM:'...
%     sprintf('\n Object dwell time')], ['data' fs 'gaze' fs 'Results' fs]);
% save('data/gaze/Results/ObserverMatEven','ObserverMatEven')

%odd
ObserverMatOdd(logical(eye(size(ObserverMatOdd)))) = 0;
[C] = squareform(ObserverMatOdd);
%even
ObserverMatEven(logical(eye(size(ObserverMatEven)))) = 0;
[D] = squareform(ObserverMatEven);

%correlation
disp('Single object dwell time')
[R, p] = corr(C', D');
disp(['pearsons r: ' num2str(R) ', p = ' num2str(p)]);
[R, p] = corr(C', D','Type','Spearman');
disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);


%for fixations: %5. split-half reliablity
[ObserverFixOdd, ~] = corr(LabeledFix.ObjectMultiFixated(:,LabeledFix.isOdd(1,:))', 'type', 'spearman', 'rows', 'complete');
[ObserverFixEven, ~] = corr(LabeledFix.ObjectMultiFixated(:,~LabeledFix.isOdd(1,:))', 'type', 'spearman', 'rows', 'complete');

%odd
ObserverFixOdd(logical(eye(size(ObserverFixOdd)))) = 0;
[A] = squareform(ObserverFixOdd);
%even
ObserverFixEven(logical(eye(size(ObserverFixEven)))) = 0;
[B] = squareform(ObserverFixEven);

%correlation
disp('Fixation count')
[R, p] = corr(A', B');
disp(['pearsons r: ' num2str(R) ', p = ' num2str(p)]);
[R, p] = corr(A', B','Type','Spearman');
disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);


%for category: %6. split-half reliablity
[ObserverMatOddCate, ~] = corr(LabeledFix.ObjectDwellsMultiCateOdd', 'type', 'spearman', 'rows', 'complete');
[ObserverMatEvenCate, ~] = corr(LabeledFix.ObjectDwellsMultiCateEven', 'type', 'spearman', 'rows', 'complete');

%odd
ObserverMatOddCate(logical(eye(size(ObserverMatOddCate)))) = 0;
[E] = squareform(ObserverMatOddCate);
%even
ObserverMatEvenCate(logical(eye(size(ObserverMatEvenCate)))) = 0;
[F] = squareform(ObserverMatEvenCate);

%correlation
disp('Category dwell time')
[R, p] = corr(E', F');
disp(['pearsons r: ' num2str(R) ', p = ' num2str(p)]);
[R, p] = corr(E', F','Type','Spearman');
disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);

