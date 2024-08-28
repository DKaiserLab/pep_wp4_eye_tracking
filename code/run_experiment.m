
sca;
close all;
clear;
rng(1) % ensure same order for all participants
dummy_mode = false; % true = to use without eye-tracker, false for normal use
%%%%%%%%%%
%imitialize logFile
logFile = -1;
%%%%%%%%%%%%%%%
%%%%%%%

%%%%%%%%%
%% Set up Titta for Tobii eye trackers
home = cd;
cd ..;
addTittaToPath;
cd(home);

%% Get setup struct and configure settings
settings = Titta.getDefaults('Tobii Pro Fusion');
settings.debugMode = true; % Enable debug output
calViz = AnimatedCalibrationDisplay();
settings.cal.drawFunction = @calViz.doDraw;
% scale down the span of the calibration point (we don't need to whole
% screen)
scaling_factor = 1.5;
settings.val.pointPos = settings.val.pointPos / scaling_factor + 0.5 - 0.5 / scaling_factor;
settings.cal.pointPos = settings.cal.pointPos / scaling_factor + 0.5 - 0.5 / scaling_factor;

%% Initialize Titta
EThndl = Titta(settings);
if dummy_mode
    EThndl = EThndl.setDummyMode();
end
EThndl.init();

try
    %% Set up
    dat = struct();
    dat.subjctNumber = input('Enter subject number: ', 's');
    dat.age = input('Enter subject age: ', 's');
    dat.gender = input('Enter subject gender (1=M, 2=F, 3=D): ', 's');
    dat.handedness = input('Enter subject handedness (1=L, 2=R, 3=M): ', 's');
    % Create participant directory
    subjectDir = fullfile('..', 'sourcedata', ['sub-', char(dat.subjctNumber)]);
    if ~exist(subjectDir, 'dir')
        mkdir(subjectDir);
    end

    % evaluate input
    if strcmp(dat.gender,'1'); dat.gender = 'male'; 
    elseif strcmp(dat.gender,'2'); dat.gender = 'female';
    else; dat.gender = 'diverse'; 
    end
    if strcmp(dat.handedness,'1'); dat.handedness = 'left'; 
    elseif strcmp(dat.handedness,'2'); dat.handedness = 'right';
    else; dat.handedness = 'mixed'; 
    end 


    % Additional metadata
    dat.date = datestr(now, 'yyyy-mm-dd');
    dat.time = datestr(now, 'HH:MM:SS');
    dat.recordingModality = 'eye-tracking';
    dat.recordingDevice = EThndl.deviceName;
    dat.serialNumber = EThndl.serialNumber;
    dat.samplingFrequency = EThndl.frequency;
    dat.viewing_dist_cm = 68;
    dat.recordingLocation = 'math. dept. JLU Giessen';
    dat.project = 'PEP_WP4';

    taskLabel = 'EyeTracking';
    % Save participant information in a JSON file
    datfilename = fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_participants.json']);
    jsonText = jsonencode(dat);
    fid = fopen(datfilename, 'w');
    if fid == -1
        error('Cannot create JSON file');
    end
    fwrite(fid, jsonText, 'char');
    fclose(fid);

    %% Open screen
    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(2);

    screens = Screen('Screens');
    screenNumber = max(screens);
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, BlackIndex(screenNumber) / 2);
    Priority(1);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Get the size of the screen
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    % Frame duration
    frame_duration = Screen('GetFlipInterval', window);
    % Center of the window
    [xCenter, yCenter] = RectCenter(windowRect);

    % Rectangle properties
    rectWidth = 50;
    rectHeight = 50;
    rect = [xCenter - rectWidth/2; yCenter - rectHeight/2; ...
        xCenter + rectWidth/2; yCenter + rectHeight/2];

    %% Instruction of the experiment
    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Courier');
    DrawFormattedText(window, 'Loading...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);

    %% Image
    load('random_images.mat', 'randomOrder');
    % Folder containing the images
    imageFolder = fullfile(pwd, '..', 'stimuli');
    % List of all image files in the folder
    imageFiles = dir(fullfile(imageFolder, '*.jpg'));
    numImages = numel(imageFiles);

    % presentation time for each image (in seconds)
    presentation_time = 3;

    %% Fixation Cross
    fixCrossDimPix = 60;
    xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
    yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
    allCoords = [xCoords; yCoords];
    lineWidthPix = 4;

    %% Calculate size for desired degree of visual angle

    % define visual angle
    x_degree = 19.9;
    y_degree = 15;

    % Viewing distance in cm
    viewing_dist = dat.viewing_dist_cm;

    % Get the screen resolution in pixels per inch
    [width, height] = Screen('DisplaySize', window); % width and height in mm
    width = width / 10; % convert to cm
    height = height / 10; % convert to cm

    % Calculate pixels per centimeter
    pixPerCmX = screenXpixels / width;
    pixPerCmY = screenYpixels / height;

    % Calculate the size in cm for the given visual angles
    sizeCmX = 2 * viewing_dist * tan(deg2rad(x_degree) / 2);
    sizeCmY = 2 * viewing_dist * tan(deg2rad(y_degree) / 2);

    % Convert the size from cm to pixels
    sizePixX = round(sizeCmX * pixPerCmX);
    sizePixY = round(sizeCmY * pixPerCmY);

    % get rectangle for image of correct size
    image_rect = CenterRectOnPointd([0 0 sizePixX sizePixY], xCenter, yCenter);


    %% Preload and resize images
    loadedImages = cell(1, numImages);
    stim_info = struct;
    for i = 1:numImages
        imgIndex = randomOrder(i);
        imagePath = fullfile(imageFolder, imageFiles(imgIndex).name);
        theImage = imread(imagePath);
        resizedImage = imresize(theImage, [sizePixY, sizePixX]);
        loadedImages{i} = resizedImage;
        % add randomized_image information
        [~,file_name,ext] = fileparts(imagePath);
        stim_info(1,i).fInfo = dir(imagePath);
        stim_info(1,i).fInfo.fname = file_name;
        stim_info(1,i).fInfo.ext   = ext;
        stim_info(i).iInfo = imfinfo(imagePath);
        stim_info(i).scrRect = image_rect;
    end

    %% Create textures for the images
    imageTextures = cell(1, numImages);
    for i = 1:numImages
        imageTextures{i} = Screen('MakeTexture', window, loadedImages{i});
    end

    %% Instruction of the experiment
    Explanation = ['In each trial, you will be presented with a picture\n' ...
        'on the screen for a short amount of time.\n' ...
        'Please view each picture freely, as you normally would.\n' ...
        'There are no right or wrong ways to view the pictures.\n' ...
        'Simply relax and look at the screen as you would in any everyday situation.\n' ...
        'Before starting each trial, you have to make sure\n' ...
        'you are looking at the center of the fixation cross(+)\n'...
        'in the middle of the screen, and then press space to continue.\n\n' ...
        'The first 6 pictures are for practice.\n\n\n\n\n'...
        'Press any key to start the practice session'];

    DrawFormattedText(window, Explanation, 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);
    KbStrokeWait;

    %% Prepare the log file
    logFilename = fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_events.tsv']);
    logFile = fopen(logFilename, 'w');

    if logFile == -1
        error('cannot open the file')
    end

    %header
    fprintf(logFile, 'trial\timage\tfixation_flip_time\tspace_press_time\timage_flip_time\timage_stop_time\n');

    %% Initialize eye tracker calibration
    ListenChar(-1);
    tobii.calVal{1} = EThndl.calibrate(window);
    ListenChar(0);

    %% Start recording eye-tracking data
    EThndl.buffer.start('gaze');
    WaitSecs(0.8);
    EThndl.sendMessage('start recording');

    %% Initialize keyboard
    KbName('UnifyKeyNames');
    abortKey = KbName('ESCAPE');
    keyPress = KbName('space');
    recalibrationPress = KbName('r');

    %% Loop through the images
    num_prc_trials = 6;
    trial = 1 - num_prc_trials; % practive trial have trialnumber <1
    for i = 1:numImages

        %% Break (after every 100 images)
        if mod(trial,100) == 1 && trial > 1
            BreakText = ['...Break...\n'...
                'You can rest for a minute.\n\n'...
                'Press any key to continue'];
            DrawFormattedText(window, BreakText, 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            Screen('Flip', window);
            EThndl.sendMessage('START BREAK', GetSecs);
            KbStrokeWait;
            EThndl.sendMessage('END BREAK', GetSecs);
        end

        % wait for 200ms
        WaitSecs(0.2)

        % Draw the fixation cross
        Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
        fixationFlipTime = Screen('Flip', window);

        %checking both x and y
        while true

            % give option to abort or recalibrate here
            [~, ~, keyCode] = KbCheck;
            if keyCode(abortKey)
                error('Experiment has been aborted');
            elseif keyCode(recalibrationPress)

                %% Initialize eye tracker re-calibration
                EThndl.sendMessage('RECALIBRATE', GetSecs);

                ListenChar(-1);
                tobii.calVal{1} = EThndl.calibrate(window);
                ListenChar(0);

                % Draw the fixation cross
                Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
                fixationFlipTime = Screen('Flip', window);

                % start recording again
                EThndl.buffer.start('gaze');
                WaitSecs(0.8);
                EThndl.sendMessage('start recording');

            end

            gazeData  = EThndl.buffer.peekN('gaze');
            gazeX = [];
            gazeY = [];
            space_press_tim = [];

            % Extract gaze coordinates (we'll use the average position of both eyes)
            if ~isempty(gazeData) || dummy_mode
                gazeX = mean([gazeData(end).left.gazePoint.onDisplayArea(1), gazeData(end).right.gazePoint.onDisplayArea(1)]) * screenXpixels;
                gazeY = mean([gazeData(end).left.gazePoint.onDisplayArea(2), gazeData(end).right.gazePoint.onDisplayArea(2)]) * screenYpixels;

                if (~isempty(gazeX) && ~isnan(gazeX) && inRect([gazeX,gazeY], rect)) || dummy_mode

                    % Wait for 'space' key press
                    [~, keyTime, keyCode] = KbCheck;
                    if keyCode(keyPress)

                        space_press_time = keyTime;
                        break;

                    elseif  keyCode(abortKey)
                        error('Experiment has been aborted');

                    end
                end
            end
        end

        % send message of events with correct timing
        % (This is executed here because in case of recalibration the FIX
        % On message would be sent twice, before and after recalibration,
        % now only the later fixation onset will we logged)
        EThndl.sendMessage('FIX ON', fixationFlipTime);
        EThndl.sendMessage('SPACE PRESS', space_press_time);

        %% Start trial

        % Display the image
        Screen('DrawTexture', window, imageTextures{i});
        imageFlipTime = Screen('Flip', window);
        current_image_name = [stim_info(1,i).fInfo.fname, stim_info(1,i).fInfo.ext];
        EThndl.sendMessage(sprintf('STIM ON: %s', current_image_name), imageFlipTime);

        % Wait for the specified duration
        elapsedTime = 0;
        while elapsedTime < (presentation_time - frame_duration * 0.5)
            [~, ~, keyCode] = KbCheck;
            if keyCode(abortKey)
                error('Experiment has been aborted');
            end
            elapsedTime = GetSecs - imageFlipTime;
        end

        % Draw the fixation cross
        Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
        imageStopTime = Screen('Flip', window);
        EThndl.sendMessage(sprintf('STIM OFF: %s', current_image_name), imageStopTime);

        % Log the trial information
        fprintf(logFile, '%d\t%s\t%.4f\t%.4f\t%.4f\t%.4f\n',...
            trial, current_image_name, fixationFlipTime, space_press_time, imageFlipTime, imageStopTime);

        %% Practice session
        if trial == 0
            Endprc = ['...The end of the Practice session...\n\n'...
                'Do you have any questions?\n\n'...
                'Press any key to start the experiment'];
            DrawFormattedText(window, Endprc, 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            EThndl.sendMessage('END OF PRACTICE', GetSecs);
            Screen('Flip', window);
            KbStrokeWait;
            %%
            %%%%%%%%%%% I add it here again
            % Initialize eye tracker re-calibration
            EThndl.sendMessage('RECALIBRATE', GetSecs);

            ListenChar(-1);
            tobii.calVal{1} = EThndl.calibrate(window);
            ListenChar(0);

            % Draw the fixation cross
            Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
            fixationFlipTime = Screen('Flip', window);

            % start recording again
            EThndl.buffer.start('gaze');
            WaitSecs(0.8);
            EThndl.sendMessage('start recording');
            EThndl.sendMessage('START EXPERIMENT', GetSecs);
        end
        
        trial = trial + 1;
    end

    %% End of Experiment
    DrawFormattedText(window, ['The end', newline, newline, 'Thank you'], 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    End_time = Screen('Flip', window);
    EThndl.sendMessage('END OF EXPERIMENT', End_time);
    WaitSecs(0.5)

    %% Stop recording
    EThndl.buffer.stop('gaze');
    WaitSecs(0.5)
    EThndl.sendMessage('STOP RECORDING', GetSecs);

    %% Save eye-tracking data
    ET_dat = EThndl.collectSessionData();
    ET_dat.expt.winRect = [0, 0, screenXpixels, screenYpixels]; % anaylsis scripts need that information
    ET_dat.expt.resolution = [screenXpixels, screenYpixels];
    ET_dat.expt.stim = stim_info;
    EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);

    %% Shut down
    EThndl.deInit();
    sca;
    %%%%
    if logFile ~= -1
        fclose(logFile);
    end
catch me
    try % try to save what has been recorded
        % Stop and save recording
        EThndl.sendMessage('ERROR - PROGRAM ABORTED', GetSecs);
        EThndl.buffer.stop('gaze');
        WaitSecs(0.5)
        EThndl.sendMessage('STOP RECORDING', GetSecs);
        ET_dat = EThndl.collectSessionData();
        ET_dat.expt.winRect = [0, 0, screenXpixels, screenYpixels]; % anaylsis scripts need that information
        ET_dat.expt.resolution = [screenXpixels, screenYpixels];
        ET_dat.expt.stim = stim_info;
        EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);
        EThndl.deInit();

        sca;
        ListenChar(0);
        %%%%%
        if logFile ~= -1
            fclose(logFile);
        end
        rethrow(me);

    catch me2

        sca;
        ListenChar(0);

        rethrow(me2);

    end
end

sca;
