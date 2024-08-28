clear variables; clear global; clear mex; close all; fclose('all'); clc
dbstop if error % for debugging: trigger a debug point when an error occurs
myDir = pwd;

% Define subjects
subs = [];
dirs.sourcedata = fullfile('..', 'sourcedata');
folders = dir(dirs.sourcedata);
for n = 1:numel(folders)
    if contains(folders(n).name, 'sub-')
        subs{end+1} = strrep(folders(n).name, 'sub-', '');
    end
end

%% Loop through subjects
for sub = subs
    if isnumeric(sub)
        sub = num2str(sub);
    elseif iscell(sub)
        sub = char(sub);
    end

    %% Setup directories
    dirs.sub = fullfile('..', 'sourcedata', ['sub-', sub]);
    dirs.msgs = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'msgs');
    if ~isfolder(dirs.msgs)
        mkdir(dirs.msgs);
    end
    dirs.samples = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'samples');
    if ~isfolder(dirs.samples)
        mkdir(dirs.samples);
    end
    dirs.funclib = fullfile(myDir, '..', '..', 'Titta', 'demo_analysis', 'function_library');
    dirs.stims = fullfile(myDir, '..', 'stimuli');
    dirs.all_fix = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'all_fixations');
    if ~isfolder(dirs.all_fix)
        mkdir(dirs.all_fix);
    end
    dirs.AOImasks = fullfile(myDir, '..', 'AOImasks');

    % Add directories path
    addpath(genpath(dirs.funclib));

    %% Get all trials, parse into subject and stimulus
    [files, nfiles] = FileFromFolder(dirs.all_fix, [], 'mat');
    files = parseFileNames(files);

    fhndl = -1;
    lastRead = '';
    for p = 1:nfiles
        % Load fix data
        dat = load(fullfile(dirs.all_fix, [files(p).fname '.mat'])); 
        dat = dat.dat;
        if isempty(dat.time)
            warning('No data for %s, empty file', files(p).fname);
            continue;
        end

        % Get msgs
        msgs = loadMsgs(fullfile(dirs.msgs, [files(p).fname '.txt']));
        [times, what, msgs] = parseMsgs(msgs);

        sessionFileName = sprintf('%s.mat', files(p).subj);
        if ~strcmp(lastRead, sessionFileName)
            sess = load(fullfile(dirs.sub, sessionFileName), 'expt');
            lastRead = sessionFileName;
            fInfo = [sess.expt.stim.fInfo];
        end
        qWhich = strcmp({fInfo.name}, what{1});

        % Load image, if available
        imgFile = fullfile(dirs.AOImasks, what{1});
        if exist(imgFile, 'file')
            img.data = imread(imgFile);
        else
            imgFile = fullfile(dirs.stims, what{1});
            if exist(imgFile, 'file')
                img.data = imread(imgFile);
            else
                img = [];
            end
        end

        if ~isempty(img)
            % Get position on screen
            stimRect = [640, 360, 1920, 1080];
            img.x = linspace(stimRect(1), stimRect(3), size(img.data, 2));
            img.y = linspace(stimRect(2), stimRect(4), size(img.data, 1));
        end

        % Plot
        if ~ishghandle(fhndl)
            fhndl = figure('Units', 'normalized', 'Position', [0 0 1 1]);  % Make fullscreen figure
        else
            figure(fhndl);
            clf;
        end
        set(fhndl, 'Visible', 'on');  % Ensure visibility
        drawFix(dat, dat.fix, [dat.I2MCopt.xres dat.I2MCopt.yres], img, [dat.I2MCopt.missingx dat.I2MCopt.missingy], sprintf('subj %s, trial %03d, stim: %s', files(p).subj, files(p).runnr, what{1}));
        
        % Pause to wait for user input (adjust as needed)
        pause(1);
        if ~ishghandle(fhndl)
            return;
        end
    end
    
    if ishghandle(fhndl)
        close(fhndl);
    end

    rmpath(genpath(dirs.funclib));  % Cleanup path
end
