function c_showFix

% this code is adapted from Titta, a toolbox providing access to
% eye tracking functionality using Tobii eye trackers
%
% Titta can be found at https://github.com/dcnieho/Titta.
%
% Niehorster, D.C., Andersson, R. & Nystrom, M., (2020). Titta: A toolbox
% for creating Psychtoolbox and Psychopy experiments with Tobii eye
% trackers. Behavior Research Methods.
% doi: https://doi.org/10.3758/s13428-020-01358-8
%
% it furthermore uses I2MC, make sure you downloaded it
% and placed it in /function_library/I2MC

myDir = pwd;

% define subjets
subs = input('Subjects (input must be a cell like {''001''}): ');

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
    dirs.samples  = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'samples');
    if ~isfolder(dirs.samples)
        mkdir(dirs.samples);
    end
    dirs.funclib  = fullfile(myDir, '..', '..', 'Titta', 'demo_analysis', 'function_library');
    dirs.stims    = fullfile(myDir, '..', 'stimuli');
    dirs.all_fix  = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'all_fixations');
    if ~isfolder(dirs.all_fix)
        mkdir(dirs.all_fix);
    end
    dirs.AOImasks = fullfile(myDir, '..', 'AOIs', 'AOImasks');

    % add directories path
    addpath(genpath(dirs.funclib));

    %% get all trials, parse into subject and stimulus
    [files,nfiles]  = FileFromFolder(dirs.all_fix,[],'mat');
    files           = parseFileNames(files);

    fhndl = -1;
    lastRead = '';
    for p = 1:nfiles
        % load fix data
        dat  = load(fullfile(dirs.all_fix,[files(p).fname '.mat'])); dat = dat.dat;
        if isempty(dat.time)
            warning('no data for %s, empty file',files(p).fname);
            continue;
        end

        % get msgs
        msgs    = loadMsgs(fullfile(dirs.msgs,[files(p).fname '.txt']));
        [times,what,msgs] = parseMsgs(msgs);

        sessionFileName = sprintf('%s.mat',files(p).subj);
        if ~strcmp(lastRead,sessionFileName)
            sess = load(fullfile(dirs.sub,sessionFileName),'expt');
            lastRead = sessionFileName;
            fInfo = [sess.expt.stim.fInfo];
        end
        qWhich= strcmp({fInfo.name},what{1});

        % load img, if only one
        if ~~exist(fullfile(dirs.AOImasks,what{1}),'file')
            img.data = imread(fullfile(dirs.AOImasks,what{1}));
        elseif ~~exist(fullfile(dirs.stims,what{1}),'file')
            img.data = imread(fullfile(dirs.stims,what{1}));
        else
            img      = [];
        end
        if ~isempty(img)
            % get position on screen
            stimRect = sess.expt.stim(p).scrRect;
            img.x    = linspace(stimRect(1),stimRect(3),size(img.data,2));
            img.y    = linspace(stimRect(2),stimRect(4),size(img.data,1));
        end

        % plot
        if ~ishghandle(fhndl)
            fhndl = figure('Units','normalized','Position',[0 0 1 1]);  % make fullscreen figure
        else
            figure(fhndl);
            clf;
        end
        set(fhndl,'Visible','on');  % assert visibility to bring window to front again after keypress
        drawFix(dat,dat.fix,[dat.I2MCopt.xres dat.I2MCopt.yres],img,[dat.I2MCopt.missingx dat.I2MCopt.missingy],sprintf('subj %s, trial %03d, stim: %s',files(p).subj,files(p).runnr,what{1}));
        pause
        if ~ishghandle(fhndl)
            return;
        end
    end
    if ishghandle(fhndl)
        close(fhndl);
    end

    rmpath(genpath(dirs.funclib));                  % cleanup path
end
end