
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

    %FixData = LabeledFix.Data{1,iSubj}; %overwrites previous FixData, which is no longer needed

%    LabeledFix.ObjectDwells(iSubj,:)       = zeros(1, NumObjsTotal);
    LabeledFix.ObjectDwellsMulti(iSubj,:)  = zeros(1, NumObjsTotal);
%   LabeledFix.ObjectFixated(iSubj,:)      = zeros(1, NumObjsTotal);
    LabeledFix.ObjectMultiFixated(iSubj,:) = zeros(1, NumObjsTotal);
    LabeledFix.ObjectDwellsMultiCate(iSubj,:) = zeros(1, height(category_file));
%    IsOdd = logical(rem(FixData(:,1),2));%mark fixations in odd trials

    ObjCount = 0;
    ObjEven  = [];
    ObjOdd   = [];
    for iImg = 1:height(all_trials)

        % get object in image
        image_name = char(log_file.image(iImg));
        ObjsInImg = dir(fullfile('..','AOIs',char(image_name),'*.png'));

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


            %             %Check if there are eyetracking data for this image from
            %             %this participant (sometimes there are missing images)
            %             if any(FixData(IsOdd,3) == uniqueIMG(iImg))
            %                 ObjOdd   = [ObjOdd ObjCount]; %used to calculate split-half
            %             elseif any(FixData(~IsOdd,3) == uniqueIMG(iImg))
            %                 ObjEven  = [ObjEven ObjCount]; %used to calculate split-half
            %             end
            %
            %             if ~any(FixData(:, 3) == uniqueIMG(iImg)) %if yes (missing)
            %                 LabeledFix.ObjectDwells(iSubj,ObjCount)      = NaN;
            %                 LabeledFix.ObjectDwellsMulti(iSubj,ObjCount) = NaN;
            %                 LabeledFix.ObjectFixCount(iSubj,iImg)        = NaN;
            %             elseif any(FixData(:, 3) == uniqueIMG(iImg)) %if there are existing eye-tracking data for this image

            % get rows with object
            fix_data_obj = fix_data(fix_data.AOINr == iObjs,:);

%             ObjRowsImg = FixData(:, 3)  == uniqueIMG(iImg);
%             ObjRowsObj = FixData(:, 11) == iObjs; %list the rows of interest
%             %multi objects
%             ObjRowsImgMulti = FixData(:, 3)     == uniqueIMG(iImg);
%             ObjRowsObjMulti = FixData(:, 12:18) == iObjs; %list the rows of interest
% 
%             [ObjRows, ObjCol] = find(ObjRowsImg & ObjRowsObj);
%             [ObjRowsMulti, ObjColMulti] = find(ObjRowsImgMulti & ObjRowsObjMulti);
% 
%             if ~isempty(ObjRows) %if the current object was indeed fixated (otherwise it will be skipped and the zero (no dwell time) will remain)
%                 LabeledFix.ObjectDwells(iSubj,ObjCount)  = nansum(FixData(ObjRows,9));%sum over all the rows were the current object was fixated and sum the durations
%                 LabeledFix.ObjectFixated(iSubj,ObjCount) = LabeledFix.ObjectFixated(iSubj,ObjCount)+length(ObjRows);
%             end

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
                    LabeledFix.ObjectDwellsMultiCate(iSubj,cate_num) = LabeledFix.ObjectDwellsMultiCate(iSubj,cate_num)...
                        + nansum(fix_data_obj.duration)/LabeledFix.ObjectDwellTotal(iSubj,iImg);
                end
            end
            %end
        end %iObjs

        %sum how many objects have been fixated by the participant in
        %the current image
        if ~any(isnan(LabeledFix.ObjectMultiFixated(iSubj,ObjCountinit:ObjCount)))
            LabeledFix.ObjectFixCount(iSubj,iImg) = sum(LabeledFix.ObjectDwellsMulti(iSubj,ObjCountinit:ObjCount)~= 0); %sum how many objects were fixated
        end
        LabeledFix.Data{iImg,iSubj} = fix_data; %write back
    end % images
end % subjects

% %4. calculate pairwise comparisons between individuals,
% %producing an Gaze Dissimilarity Matrix (GDM) by using
% %euclidian distances (provides very similar results as correlation)
% ObserverMatObjects     = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectDwellsMulti, 0, 2),@naneucdist),0,1));
% ObserverMatObjectsFix  = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectMultiFixated, 0, 2),@naneucdist),0,1));
% %pdist doesn't work with correlation as there are nans in the matrix: ObserverMatObjectsC = squareform(rescale(pdist(LabeledFix.ObjectDwells,'correlation'),0,1));
% 
% %     ObserverMatObjectsC = [zeros(30,30)];
% %     for iParticipant1 = 1:30
% %         for iParticipant2 = 1:30
% %             PairCorr = corrcoef(LabeledFix.ObjectDwellsMulti(iParticipant1,:), LabeledFix.ObjectDwellsMulti(iParticipant2,:),'rows','pairwise');
% %             ObserverMatObjectsC(iParticipant1,iParticipant2) = PairCorr(1,2);
% %         end
% %     end
% %     ObserverMatObjectsC = 1-ObserverMatObjectsC;
% %     ObserverMatObjectsC = rescale(ObserverMatObjectsC,0,1);
% 
% %5. split-half reliablity
% ObserverMatOdd  = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectDwellsMulti(:, ObjOdd),0,2),@naneucdist),0,1));
% ObserverMatEven = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectDwellsMulti(:, ObjEven),0,2),@naneucdist),0,1));
% fs = filesep();
% CreateDissimilarityPlots(ObserverMatOdd, 'ObserverMatObjectsOdd', ['GDM:'...
%     sprintf('\n Object dwell time')], ['data' fs 'gaze' fs 'Results' fs]);
% save('data/gaze/Results/ObserverMatOdd','ObserverMatOdd')
% CreateDissimilarityPlots(ObserverMatEven, 'ObserverMatObjectsEven', ['GDM:'...
%     sprintf('\n Object dwell time')], ['data' fs 'gaze' fs 'Results' fs]);
% save('data/gaze/Results/ObserverMatEven','ObserverMatEven')
% %odd
% [C] = triuMatrix(ObserverMatOdd);
% %even
% [D] = triuMatrix(ObserverMatEven);
% 
% %correlation
% [R, p] = corr(C, D);
% disp(['pearsons r: ' num2str(R) ', p = ' num2str(p)]);
% [R, p] = corr(C, D,'Type','Spearman');
% disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);
% 
% 
% %for fixations: %5. split-half reliablity
% ObserverFixOdd  = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectMultiFixated(:, ObjOdd),0,2),@naneucdist),0,1));
% ObserverFixEven = squareform(rescale(pdist(nanzscore(LabeledFix.ObjectMultiFixated(:, ObjEven),0,2),@naneucdist),0,1));
% 
% %odd
% [A] = triuMatrix(ObserverFixOdd);
% %even
% [B] = triuMatrix(ObserverFixEven);
% 
% %correlation
% [R, p] = corr(A, B);
% disp(['pearsons r: ' num2str(R) ', p = ' num2str(p)]);
% [R, p] = corr(A, B,'Type','Spearman');
% disp(['spearman r: ' num2str(R) ', p = ' num2str(p)]);

