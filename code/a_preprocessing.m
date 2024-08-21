% this code is adapted from Titta, a toolbox providing access to
% eye tracking functionality using Tobii eye trackers
%
% Titta can be found at https://github.com/dcnieho/Titta.
%
% Niehorster, D.C., Andersson, R. & Nystrom, M., (2020). Titta: A toolbox
% for creating Psychtoolbox and Psychopy experiments with Tobii eye
% trackers. Behavior Research Methods.
% doi: https://doi.org/10.3758/s13428-020-01358-8

clear variables; clear global; clear mex; close all; fclose('all'); clc
dbstop if error % for debugging: trigger a debug point when an error occurs
myDir = pwd;

% define subjets
subs = [];
dirs.sourcedata = fullfile('..','sourcedata');
folders = dir(dirs.sourcedata);
for n = numel(folders)
    if contains({folders(n).name},'sub-')
        subs{end+1} = strrep(folders(n).name, 'sub-', '');
    end
end

%% loop through subjects
for sub = subs

    if isnumeric(sub)
        sub = num2str(sub);
    elseif iscell(sub)
        sub = char(sub);
    end

    %% setup directories
    dirs.sub   = fullfile('..','sourcedata', ['sub-', sub]);   % directory where subject mat files are placed
    dirs.msgs  = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'msgs');
    if ~isfolder(dirs.msgs)
        mkdir(dirs.msgs);
    end
    dirs.samples = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'samples');
    if ~isfolder(dirs.samples)
        mkdir(dirs.samples);
    end
    dirs.validation = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'validation');
    if ~isfolder(dirs.validation)
        mkdir(dirs.validation);
    end
    dirs.funclib = fullfile(myDir, '..', '..', 'Titta', 'demo_analysis', 'function_library');
    dirs.stims   = fullfile(myDir, '..', 'stimuli');

    % add directories path
    addpath(genpath(dirs.funclib));

    % get files
    [files,nfiles] = FileFromFolder(dirs.sub,[],'mat');

    %% cut up the data file into trials
    for p=1:nfiles
        disp(files(p).name)
        % read msgs and data
        dat     = load(fullfile(dirs.sub,files(p).name));
        scrRes  = dat.expt.resolution;
        ts      = dat.data.gaze.systemTimeStamp;
        % the Pro SDK does not guarantee invalid data is nan. Set to nan if
        % invalid
        dat.data.gaze. left.gazePoint.onDisplayArea(:,~dat.data.gaze. left.gazePoint.valid) = nan;
        dat.data.gaze.right.gazePoint.onDisplayArea(:,~dat.data.gaze.right.gazePoint.valid) = nan;
        dat.data.gaze. left.pupil.diameter(~dat.data.gaze. left.pupil.valid) = nan;
        dat.data.gaze.right.pupil.diameter(~dat.data.gaze.right.pupil.valid) = nan;
        % collect data from the file, and turn gaze positions from normalized
        % coordinates into pixels
        samp    = [bsxfun(@times,dat.data.gaze.left.gazePoint.onDisplayArea,scrRes.'); bsxfun(@times,dat.data.gaze.right.gazePoint.onDisplayArea,scrRes.'); dat.data.gaze.left.pupil.diameter; dat.data.gaze.right.pupil.diameter];
        header  = {'t','gaze_point_LX','gaze_point_LY','gaze_point_RX','gaze_point_RY','pupil_diameter_L','pupil_diameter_R'};

        % remove 'FIX ON' messages after start recording
        start_msgs = find(strcmp(dat.messages(:,2),'start recording'));
        for start_msg = start_msgs'
            previous_msg = dat.messages(start_msg-1,2);

            % check if previous message was a 'FIX ON'
            if strcmp(previous_msg, 'FIX ON')
                dat.messages(start_msg-1,2) = {'SHOW FIXATION'};
            end
        end


        % parse messages by trials
        [timest,what,msgs] = parseMsgs(dat.messages);
        %%%
        timest.fix = timest.fix(7: end,1);
        timest.start = timest.start(7:end, 1);
        timest.end = timest.end(7:end, 1);
        msgs = msgs(7:end);
        what = what(7:end);

        % split up trials and write
        for q=1:length(timest.fix) % loop through trials
            fname = sprintf('%s_R%03d.txt',files(p).fname,q);
            fprintf('%s\n',fname);

            % msgs
            fid = fopen(fullfile(dirs.msgs,fname),'wt');
            t = msgs{q}.';
            fprintf(fid,'%d\t%s\n',t{:});
            fclose(fid);

            % data
            fid = fopen(fullfile(dirs.samples,fname),'wt');
            fmt = repmat('%s\t',1,length(header));
            fmt(end) = 'n';
            % header
            fprintf(fid,fmt,header{:});
            % data
            fmt = ['%ld\t' repmat('%.2f\t',1,length(header)-3) repmat('%.4f\t',1,2)];
            fmt(end) = 'n';
            qSel = ts>=timest.fix(q) & ts<=timest.end(q);
            data = [num2cell(ts(qSel)); num2cell(samp(:,qSel))];
            fprintf(fid,fmt,data{:});
            fclose(fid);

            % copy stimuli, if needed
            fInfo  = [dat.expt.stim.fInfo];
            qWhich = strcmp({fInfo.name},what{q});
            imgFile     = fullfile(dat.expt.stim(qWhich).fInfo.folder,what{q});
            imgFileOut  = fullfile(dirs.stims,what{q});
            if exist(imgFile,'file') && ~exist(imgFileOut,'file')
                copyfile(imgFile,imgFileOut,'f');
            end

            %% validation

            % load calibration data file
            C = load(fullfile(dirs.sub,files(p).name),'calibration');
            if C.calibration{end}.wasSkipped
                acc = nan(1,4);
            elseif strcmp(C.calibration{end}.type,'standard')
                sel = C.calibration{end}.selectedCal;
                cal = C.calibration{end}.attempt{sel};
                if ~isfield(cal.val{end},'acc1D')
                    % no validation done
                    acc = nan(1,8);
                else
                    acc = [cal.val{end}.acc1D cal.val{end}.RMS1D cal.val{end}.STD1D cal.val{end}.dataLoss*100]; % each [L R]
                end
            elseif strcmp(C.calibration{end}.type,'advanced')
                sel = C.calibration{end}.selectedCal;
                cal = C.calibration{end}.attempt{sel(1)};
                if ~isfield(cal,'val')
                    % no validation done
                    acc = nan(1,8);
                else
                    % find the active/last valid validation for this
                    % calibration, if any
                    whichCals = cellfun(@(x) x.whichCal, cal.val);
                    idx     = find(whichCals==sel(2),1,'last');
                    if isempty(idx) || ~isfield(cal.val{idx},'allPoints')
                        % no validation done for this calibration, or all
                        % validation data discarded again by operator
                        acc = nan(1,8);
                    else
                        acc = [cal.val{idx}.allPoints.acc1D cal.val{idx}.allPoints.RMS1D cal.val{idx}.allPoints.STD1D cal.val{idx}.allPoints.dataLoss*100]; % each [L R]
                    end
                end
            end
        end % trial loop
    end % file loop

    rmpath(genpath(dirs.funclib));                  % cleanup path
end % subject loop