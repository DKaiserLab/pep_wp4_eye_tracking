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

% add directories path
dirs.funclib = fullfile(myDir, '..', '..', 'Titta', 'demo_analysis', 'function_library');
dirs.stims   = fullfile(myDir, '..', 'stimuli');
dirs.AOIs = fullfile(myDir, '..', 'AOIs');
addpath(genpath(dirs.funclib));


% load all AOIs
disp('Loading AOIs...')
if ~isfolder(dirs.AOIs)
    warning('AOI folder is missing');
end
AOI     = loadAllAOIFolders(dirs.AOIs,'png');
AOInms  = {AOI.name};

% define subjets
subs = [];
dirs.sourcedata = fullfile('..','sourcedata');
folders = dir(dirs.sourcedata);
for n = 1:numel(folders)
    if contains({folders(n).name},'sub-')
        subs = [subs, {strrep(folders(n).name, 'sub-', '')}];
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
    dirs.AOIfix = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'AOIfix');
    if ~isfolder(dirs.AOIfix)
        mkdir(dirs.AOIfix);
    end
    dirs.all_fix  = fullfile(myDir, '..', 'derivatives', ['sub-', sub], 'all_fixations');
    if ~isfolder(dirs.all_fix)
        mkdir(dirs.all_fix);
    end
 
    % add directories path
    addpath(genpath(dirs.funclib));

    %% check if subject was preprocessed already

    % check sample output folder
    check_files = dir(dirs.AOIfix);

%     % check if files exist already, if yes skip that subject
%     if length({check_files.name}) > 100
% 
%         % run time control
%         disp(['Files for subject ', sub, ' already exist. Subject will be skipped'])
%         continue
%     end

    %% get all trials, parse into subject and stimulus
    [files,nfiles] = FileFromFolder(dirs.all_fix,[],'mat');
    files           = parseFileNames(files);


    % per subject, per trial, read data and see which AOIs fixations are in, if
    % any. 0 is other (no AOI), -1 is not on stimulus, -2 is out of screen
    lastRead= '';
    for p=1:nfiles
        disp(files(p).fname)

        % load fix data
        dat     = load(fullfile(dirs.all_fix,[files(p).fname '.mat'])); dat = dat.dat;

        if isempty(dat.time)
            warning('no data for %s, empty file',files(p).fname);
            continue;
        end

        % get msgs
        msgs    = loadMsgs(fullfile(dirs.msgs,[files(p).fname '.txt']));
        [times,what,~] = parseMsgs(msgs);

        sessionFileName = sprintf('%s.mat',files(p).subj);
        if ~strcmp(lastRead,sessionFileName)
            sess = load(fullfile(dirs.sub,sessionFileName),'expt');
            lastRead = sessionFileName;
            fInfo = [sess.expt.stim.fInfo];
        end
        qWhich= strcmp({fInfo.name},what{1});
        assert(sum(qWhich)==1,'No or too many presentation info (texs field) found for this stimulus')

        % get more info about stimulus shown etc
        tex     = sess.expt.stim(qWhich);
        qAOI    = strcmp(what{1},AOInms);
        assert(sum(qAOI)==1,'No or too many AOIs lists found for this stimulus: %s',what{1})

        % throw out fixations that onset earlier than 100 ms after stimulus onset
        qDel = dat.fix.startT<=100;
        fields = fieldnames(dat.fix);
        for f=1:length(fields)
            if ~isscalar(dat.fix.(fields{f}))
                dat.fix.(fields{f})(qDel) = [];
            end
        end

        % check sizes are correct, i.e., AOI boolean images match in size with
        % shown images
        AOIbools    = {AOI(qAOI).AOIs.bool};
        szs         = cellfun(@size,AOIbools,'uni',false);
        tex.size = [tex.iInfo.Height, tex.iInfo.Width];
        assert(isequal(tex.size,szs{:}),'Some AOIs have wrong size (doesn''t match stimulus)');

        % get scaling factor
        imageWidth = tex.scrRect(3) - tex.scrRect(1);
        imageHeight = tex.scrRect(4) - tex.scrRect(2);

        scaleFacHeight = imageHeight/tex.size(1);
        scaleFacWidth = imageWidth/tex.size(2); 
        assert(round(scaleFacHeight, 1) == round(scaleFacWidth, 1))
        tex.scaleFac = mean([scaleFacHeight,scaleFacWidth]);


        %%% add 0.5° visual angle as tolerance to the mask

        % get tolerance area
        if ~exist('tolerance', 'var')

            % Visual angle in height (degrees)
            visual_angle_height = 15;

            % Calculate the height of the image in pixels
            coords = sess.expt.stim(p).scrRect;
            height_pixels = coords(4) - coords(2);  % bottom - top

            % Calculate pixels per degree
            pixels_per_degree = height_pixels / visual_angle_height;

            % Calculate pixels for 0.5° of visual angle
            tolerance = pixels_per_degree * 0.5;

            % Calculate circular tolerance area
            tolerance_area = strel('disk', round(tolerance) + 1);
        end
 
        % Create a structuring element with a round shape to extend the mask
        currentAOIs = AOI(qAOI).AOIs;       
        for iAOI = 1:length(currentAOIs)
            % Dilate the mask by the structuring element
            currentAOIs(iAOI).bool = imdilate(currentAOIs(iAOI).bool, tolerance_area);
        end

        % see which AOIs fixations are in
        temp    = detAOIfix(currentAOIs,dat.fix.xpos,dat.fix.ypos,sess.expt.winRect(3:4),tex.scrRect,1./tex.scaleFac);

        % use fixation ID to find corresponding info about the fixations.
        % This as one fixation can be in multiple AOIs
        fixAOI          = cell(size(temp,1),11);
        fixAOI(:,2)     = temp(:,1);    % fixation sequence number
        fixAOI(:,10:11) = temp(:,2:3);  % AOI sequence number and name
        for r=1:size(fixAOI,1)
            fnr = fixAOI{r,2};
            fixAOI(r,[1 3:9]) = {what{1},dat.fix.startT(fnr)/1000,dat.fix.dur(fnr)/1000,dat.fix.xpos(fnr),dat.fix.ypos(fnr),dat.fix.RMSxy(fnr),dat.fix.BCEA(fnr),dat.fix.fracinterped(fnr)*100};
        end

        % open file, write data
        fid = fopen(fullfile(dirs.AOIfix,[files(p).fname '.tsv']),'wt');
        fprintf(fid,'stimulus name\tfixNr\tstartT\tduration\tX (pix)\tY (pix)\tRMS\tBCEA\tdata loss (%%)\tAOI nr\tAOI name\n');
        schrijfdata = fixAOI.';
        fprintf(fid,'%s\t%d\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.3f\t%.1f\t%d\t%s\n',schrijfdata{:});
        fclose(fid);
    end

    fclose('all');

end

rmpath(genpath(dirs.funclib));