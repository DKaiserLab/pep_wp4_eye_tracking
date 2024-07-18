sca;
close all;
clear;
rng(1) % ensure same order for all participants
dummy_mode = true; % true = to use without eye-tracker, false for normal use

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
    %%%%%%% new Set up ( shorter) %%%%%%%%%%%
    dat = struct();
    dat.subjctNumber = input('Enter subject number: ', 's');
    dat.age = input('Enter subject age: ', 's');
    dat.gender = input('Enter subject gender (1=M, 2=F, 3=D): ', 's');
    % Create participant directory
    subjectDir = fullfile('..', 'sourcedata', ['sub-', char(dat.subjctNumber)]);
    if ~exist(subjectDir, 'dir')
        mkdir(subjectDir);
    end

    % Additional metadata
    dat.date = datestr(now, 'yyyy-mm-dd');
    dat.time = datestr(now, 'HH:MM:SS');
    dat.recordingModality = 'eye-tracking';
    dat.recordingDevice = EThndl.deviceName;
    dat.serialNumber = EThndl.serialNumber;
    dat.samplingFrequency = EThndl.frequency;
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
    rectWidth = 100;
    rectHeight = 100;
    rect = [xCenter - rectWidth/2; yCenter - rectHeight/2; ...
        xCenter + rectWidth/2; yCenter + rectHeight/2];

    %% Instruction of the experiment
    Screen('TextSize', window, 70);
    Screen('TextFont', window, 'Courier');
    DrawFormattedText(window, '...Explanation...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);
    KbStrokeWait;

    %% Image
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

    %% new Fixation Cross
    fixCrossDimPix2 = 40;
    xCoord2 = [-fixCrossDimPix2 fixCrossDimPix2 0 0];
    yCoord2 = [0 0 -fixCrossDimPix2 fixCrossDimPix2];
    allCoord2 = [xCoord2; yCoord2];
    lineWidthPix2 = 5;

    %% Calculate size for desired degree of visual angle

    % define visual angle
    x_degree = 19.9;
    y_degree = 15;

    % Viewing distance in cm
    viewing_dist = 60;

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
        imagePath = fullfile(imageFolder, imageFiles(i).name);
        theImage = imread(imagePath);
        resizedImage = imresize(theImage, [sizePixY, sizePixX]);
        loadedImages{i} = resizedImage;
        % add stimuli information
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

    %% Prepare the log file
    logFilename = fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_events.tsv']);
    logFile = fopen(logFilename, 'w');
    %header
    fprintf(logFile, 'trial\timage\tfixation_flip_time\tspace_press_time\timage_flip_time\timage_stop_time\wait_duration\n');

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
    num_prc_trials = 10;
    trial = 1 - num_prc_trials; % practive trial have trialnumber <1
    for i = 1:numImages

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


                        % Draw the NEW green fixation cross
                        Screen('DrawLines', window, allCoord2, lineWidthPix2, [0 1 0], [xCenter yCenter], 2);
                        Screen('Flip', window);
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

        % random duration between 0.1 and 0.5 seconds
        wait_duration = 0.1 + rand() * 0.4;
        WaitSecs(wait_duration);

        % Display the image
        Screen('DrawTexture', window, imageTextures{i});
        imageFlipTime = Screen('Flip', window);
        EThndl.sendMessage(sprintf('STIM ON: %s', imageFiles(i).name), imageFlipTime);

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
        EThndl.sendMessage(sprintf('STIM OFF: %s', imageFiles(i).name), imageStopTime);

        % Log the trial information
        fprintf(logFile, '%d\t%s\t%.4f\t%.4f\t%.4f\t%.4f\t%.4f\n',...
            trial, imageFiles(i).name, fixationFlipTime, space_press_time, imageFlipTime, imageStopTime, wait_duration);

        %% Practice session
        if trial == 0
            DrawFormattedText(window, '...The end of the Practice session...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            EThndl.sendMessage('END OF PRACTICE', GetSecs);
            Screen('Flip', window);
            KbStrokeWait;
            EThndl.sendMessage('START EXPERIMENT', GetSecs);
        end

        %% Break (after every 100 images)
        if mod(trial,100) == 0
            DrawFormattedText(window, '...Break...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            Screen('Flip', window);
            EThndl.sendMessage('START BREAK', GetSecs);
            KbStrokeWait;
            EThndl.sendMessage('END BREAK', GetSecs);

            %% Initialize eye tracker re-calibration
            EThndl.sendMessage('RECALIBRATE', GetSecs);

            ListenChar(-1);
            tobii.calVal{1} = EThndl.calibrate(window);
            ListenChar(0);

            % Draw the fixation cross
            Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
            fixationFlipTime = Screen('Flip', window);
            %on
            EThndl.sendMessage('FIX ON', fixationFlipTime);

            % start recording again
            EThndl.buffer.start('gaze');
            WaitSecs(0.8);
            EThndl.sendMessage('start recording');
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
    ET_dat.expt.resolution = [screenXpixels, screenYpixels];
    ET_dat.expt.stim = stim_info;
    EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);

    %% Shut down
    EThndl.deInit();
    sca;
    fclose(logFile);
catch me
    try % try to save what has been recorded
        % Stop and save recording
        EThndl.sendMessage('ERROR - PROGRAM ABORTED', GetSecs);
        EThndl.buffer.stop('gaze');
        WaitSecs(0.5)
        EThndl.sendMessage('STOP RECORDING', GetSecs);
        ET_dat = EThndl.collectSessionData();
        ET_dat.expt.resolution = [screenXpixels, screenYpixels];
        ET_dat.expt.stim = stim_info;
        EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);
        EThndl.deInit();

        sca;
        ListenChar(0);
        fclose(logFile);
        rethrow(me);

    catch me2

        sca;
        ListenChar(0);
        fclose(logFile);
        rethrow(me2);

    end
end
sca;
