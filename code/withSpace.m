sca;
close all;
clear;
rng(1) % ensure same order for all participants

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
    dat.recordingDevice = 'Tobii Pro Fusion';
    dat.samplingFrequency = '120 Hz';  % Assuming the sampling frequency, adjust if necessary
    dat.recordingLocation = 'math. dept. JLU Giessen';
    dat.project = 'PEP_WP4';

    taskLabel = 'EyeTracking';
    % Save participant information in a JSON file
    datfilename = fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, 'participants.json']);
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

    %% Preload and resize images
    %width
    resizedWidth = 0.5 * screenXpixels;
    %height
    resizedHeight = 0.5 * screenYpixels;
    loadedImages = cell(1, numImages);
    for i = 1:numImages
        imagePath = fullfile(imageFolder, imageFiles(i).name);
        theImage = imread(imagePath);
        % Resize the image
        resizedImage = imresize(theImage, [resizedHeight, resizedWidth]);
        loadedImages{i} = resizedImage;
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
    fprintf(logFile, 'trial\timage\tfixation_flip_time\timage_flip_time\timage_stop_time\n');

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
    trial = 1;
    for i = 1:numImages
        % Check for keyboard input
        [~, ~, keyCode] = KbCheck;
        if keyCode(abortKey)
            error('Experiment has been aborted');
        end

        % Draw the fixation cross
        Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
        fixationFlipTime = Screen('Flip', window);
        %on
        EThndl.sendMessage(sprintf('FIX ON: %s', imageFiles(i).name), fixationFlipTime);

        %checking both x and y
        while true

            % give option to abort or recalibrate here
            [~, ~, keyCode] = KbCheck;
            if keyCode(abortKey)
                error('Experiment has been aborted');
            elseif keyCode(recalibrationPress)

                EThndl.sendMessage(sprintf('RECAL: %s', imageFiles(i).name), GetSecs);

                %% Initialize eye tracker calibration
                ListenChar(-1);
                tobii.calVal{1} = EThndl.calibrate(window);
                ListenChar(0);

                % Draw the fixation cross
                Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
                fixationFlipTime = Screen('Flip', window);
                %on
                EThndl.sendMessage(sprintf('FIX ON: %s', imageFiles(i).name), fixationFlipTime);
            end

            gazeData  = EThndl.buffer.peekN('gaze');% chatgpt suggested to use peek:)
            gazeX = [];
            gazeY = [];
            % Extract gaze coordinates (we'll use the average position of both eyes)
            if ~isempty(gazeData)
                gazeX = mean([gazeData(end).left.gazePoint.onDisplayArea(1), gazeData(end).right.gazePoint.onDisplayArea(1)]) * screenXpixels;
                gazeY = mean([gazeData(end).left.gazePoint.onDisplayArea(2), gazeData(end).right.gazePoint.onDisplayArea(2)]) * screenYpixels;

                if ~isempty(gazeX) && ~isnan(gazeX) && inRect([gazeX,gazeY], rect)

                    % Wait for 'space' key press
                    [~, ~, keyCode] = KbCheck;
                    if keyCode(keyPress)
                        % send message
                        EThndl.sendMessage(sprintf('SPACE PRESS: %s', imageFiles(i).name), fixationFlipTime);

                        % Draw the NEW green fixation cross
                        Screen('DrawLines', window, allCoord2, lineWidthPix2, [0 1 0], [xCenter yCenter], 2);
                        fixationFlipTime = Screen('Flip', window);
                        break;

                    elseif  keyCode(abortKey)
                        error('Experiment has been aborted');

                    end
                end
            end
        end

        %% Start trial

        % random duration between 0.50 and 1 seconds
        wait_duration = 0.5 + rand() * 0.5;
        WaitSecs(wait_duration);

        % Display the image
        Screen('DrawTexture', window, imageTextures{i});
        imageFlipTime = Screen('Flip', window);
        EThndl.sendMessage(sprintf('STIM ON: %s', imageFiles(i).name), imageFlipTime);

        % Wait for the specified duration
        elapsedTime = 0;
        start_time = GetSecs;
        while elapsedTime < (presentation_time - frame_duration * 0.5)
            [~, ~, keyCode] = KbCheck;
            if keyCode(abortKey)
                error('Experiment has been aborted');
            end
            elapsedTime = GetSecs - start_time;
        end

        % Draw the fixation cross
        Screen('DrawLines', window, allCoords, lineWidthPix, WhiteIndex(screenNumber), [xCenter yCenter], 2);
        imageStopTime = Screen('Flip', window);
        EThndl.sendMessage(sprintf('STIM OFF: %s', imageFiles(i).name), imageStopTime);
        % is it okay?
        WaitSecs(0.2)


        % Log the trial information
        fprintf(logFile, '%d\t%s\t%.4f\t%.4f\n', trial, imageFiles(i).name, imageFlipTime, fixationFlipTime, imageStopTime);

        %% Practice session
        if trial == 3
            DrawFormattedText(window, '...The end of the Practice session...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            Screen('Flip', window);
            KbStrokeWait;
        end

        %% Break (we have to change here)
        if trial == 5
            DrawFormattedText(window, '...Break...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
            Screen('Flip', window);
            KbStrokeWait;
        end

        trial = trial + 1;
    end

    %% Stop recording
    EThndl.buffer.stop('gaze');

    %% Save eye-tracking data
    ET_dat = EThndl.collectSessionData();
    ET_dat.expt.resolution = [screenXpixels, screenYpixels];
    EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);

    %% Shut down
    EThndl.deInit();
    sca;
    fclose(logFile);
catch me
    try
        % Stop and save recording
        EThndl.buffer.stop('gaze');
        ET_dat = EThndl.collectSessionData();
        ET_dat.expt.resolution = [screenXpixels, screenYpixels];
        EThndl.saveData(ET_dat, fullfile(subjectDir, ['sub-', dat.subjctNumber, '_task-', taskLabel, '_physio']), true);
        EThndl.deInit();

        sca;
        ListenChar(0);
        fclose(logFile);
        rethrow(me);

    catch

        sca;
        ListenChar(0);
        fclose(logFile);
        rethrow(me);

    end
end
sca;
