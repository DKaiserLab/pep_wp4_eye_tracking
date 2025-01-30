sca;
close all;
clear;
rng(1);

try
    %% Setup
    dat = struct();
    dat.subjctNumber = input('Enter subject number: ', 's');

    % participant directory
    currentDir = pwd;
    subjectDir = fullfile(currentDir, '..', '..', 'sourcedata', ['sub-', char(dat.subjctNumber)]);
    if ~exist(subjectDir, 'dir')
        mkdir(subjectDir);
    end

    %% Open screen
    Screen('Preference', 'SkipSyncTests', 1);
    PsychDefaultSetup(2);
    HideCursor;
    screens = Screen('Screens');
    screenNumber = max(screens);
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, BlackIndex(screenNumber));
    Priority(1);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

    % Screen properties
    [screenXpixels, screenYpixels] = Screen('WindowSize', window);
    [xCenter, yCenter] = RectCenter(windowRect);

    %% screen
    % define visual angle
    x_degree = 19.9;
    y_degree = 15;

    % Viewing distance in cm
    dat.viewing_dist_cm = 68;
    viewing_dist = dat.viewing_dist_cm;

    % Get the screen resolution in pixels per cm
    [scWidth, scHeight] = Screen('DisplaySize', window); % width and height in mm
    scWidth = scWidth / 10; % convert to cm
    scHeight = scHeight / 10; % convert to cm

    % Calculate pixels per centimeter
    pixPerCmX = screenXpixels / scWidth;
    pixPerCmY = screenYpixels / scHeight;

    % Calculate the size in cm for the given visual angles
    sizeCmX = 2 * viewing_dist * tan(deg2rad(x_degree) / 2);
    sizeCmY = 2 * viewing_dist * tan(deg2rad(y_degree) / 2);

    % Convert the size from cm to pixels
    sizePixX = round(sizeCmX * pixPerCmX);
    sizePixY = round(sizeCmY * pixPerCmY);

    %% Experiment Instructions
    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Courier');
     Explanation = ['Two pictures will appear: one on the left and one on the right.\n\n'...
                               'Identify which picture appeared in the eye-tracking experiment.\n\n'...
                               'Press the left arrow key if the correct picture is on the left.\n'...
                               'Press the right arrow key if the correct picture is on the right.\n\n\n'...
                               'Press any key to start'];
                               

    DrawFormattedText(window, Explanation, 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);
    KbStrokeWait;
    DrawFormattedText(window, 'Loading...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);

    % Load .mat files
    trialOrder = readtable('trialOrder.xlsx','Format','auto');

    % Validate the loaded variables
    if ~exist('trialOrder', 'var')
        error('The variable "trialOrder" was not found in trialOrder.mat.');
    end

    % Preload images
    numImages = height(trialOrder); % Number of trials from trialOrder.mat
    loadedImagesl = cell(1, numImages);
    loadedImagesr = cell(1, numImages);

    % File folders
    expImgFolder = fullfile(pwd, '..', '..', 'stimuli');
    novelImgFolder = fullfile(pwd, '..', '..', 'stimuli', 'novelImagesMemeoryTask');

    for i = 1:numImages

        % Allocate image directories accroding to trialOrder
        if strcmp(trialOrder.expImgLocation{i}, 'right')
            imagePathl = fullfile(novelImgFolder, trialOrder.novelImg{i});
            imagePathr = fullfile(expImgFolder, trialOrder.expImg{i});
        else
            imagePathl = fullfile(expImgFolder, trialOrder.expImg{i});
            imagePathr = fullfile(novelImgFolder, trialOrder.novelImg{i});
        end

        % Load and resize the images
        theImagel = imread(imagePathl);
        theImager = imread(imagePathr);

        loadedImagesl{i} = imresize(theImagel, [sizePixY, sizePixX]);
        loadedImagesr{i} = imresize(theImager, [sizePixY, sizePixX]);
    end

    %% Create textures for the images
    imageTexturesl = cell(1, numImages);
    imageTexturesr = cell(1, numImages);

    for i = 1:numImages
        imageTexturesl{i} = Screen('MakeTexture', window, loadedImagesl{i});
        imageTexturesr{i} = Screen('MakeTexture', window, loadedImagesr{i});
    end

    %% Keyboard setup
    KbName('UnifyKeyNames');
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    abortKey = KbName('ESCAPE');

    %% Define positions for left and right images

    % define postion based on visual angle
    x_postion = x_degree/2 + 2;

    % Calculate the size in cm for the given visual angles
    postionCmX = 2 * viewing_dist * tan(deg2rad(x_postion) / 2);

    % Convert the size from cm to pixels
    postionPixX = round(pixPerCmX * postionCmX);

    % 30% of screen width
    leftX = xCenter - postionPixX;
    rightX = xCenter + postionPixX;
    imageY = yCenter;

    %% Run trials
    results = cell(numImages, 3);
    fprintf('Starting trials...\n');

    for k = 1:numImages
        % Wait for key press
        KbReleaseWait;

        %% important
        % Reset `choice` for the trial
        choice = '';
        fprintf('Trial %d: Preparing images...\n', k);

        % Draw images
        leftRect = CenterRectOnPoint([0, 0, size(loadedImagesl{k}, 2), size(loadedImagesl{k}, 1)], leftX, imageY);
        rightRect = CenterRectOnPoint([0, 0, size(loadedImagesr{k}, 2), size(loadedImagesr{k}, 1)], rightX, imageY);

        Screen('DrawTexture', window, imageTexturesl{k}, [], leftRect);
        Screen('DrawTexture', window, imageTexturesr{k}, [], rightRect);
        Screen('Flip', window);

        % Wait for response
        tStart = GetSecs;
        while isempty(choice)
            [keyIsDown, ~, keyCode] = KbCheck;
            if keyIsDown
                if keyCode(abortKey)
                    error('Experiment has been aborted');
                elseif keyCode(leftKey)
                    choice = 'left';
                elseif keyCode(rightKey)
                    choice = 'right';
                end
            end
            WaitSecs(0.01);
        end
        tEnd = GetSecs;

        %% Record response
        dat.results{k, 1} = trialOrder.expImg{k}; % experiment Image
        dat.results{k, 2} = trialOrder.novelImg{k}; % experiment Image
        dat.results{k, 3} = trialOrder.expImgLocation{k}; % side of experiment image
        dat.results{k, 4} = choice; % Choice (left or right)
        dat.results{k, 5} = num2str(strcmp(choice, ...
            trialOrder.expImgLocation{k})); % Accuracy
        dat.results{k, 6} = trialOrder.category{k}; % Category

        fprintf('Trial %d complete. Choice: %s, Reaction Time: %.2f s\n', k, choice, tEnd - tStart);

        %% Give feedback
        if logical(str2double(dat.results{k, 5}))
            DrawFormattedText(window, 'Correct', 'center', 'center', WhiteIndex(screenNumber));
            Screen('Flip', window);
        else
            DrawFormattedText(window, 'Incorrect', 'center', 'center', WhiteIndex(screenNumber));
            Screen('Flip', window);
        end

        WaitSecs(0.5);
    end

    %% Save results
    fprintf('Saving results...\n');
    resultsFile = fullfile(subjectDir, ['memory_task_sub-', char(dat.subjctNumber), '.mat']);
    save(resultsFile, 'dat');
    fprintf('Results saved successfully.\n');

    %% end messagee
    DrawFormattedText(window, 'Thank you for participating!', 'center', 'center', WhiteIndex(screenNumber));
    Screen('Flip', window);
    WaitSecs(2);

    %% Close Psychtoolbox
    ShowCursor;
    Priority(0);
    sca;

catch ME

    try
        %% Save results
        fprintf('Saving results...\n');
        resultsFile = fullfile(subjectDir, ['results_sub-', char(dat.subjctNumber), '.mat']);
        save(resultsFile, 'dat');
        fprintf('Results saved successfully.\n');

        %% end messagee
        DrawFormattedText(window, 'Thank you for participating!', 'center', 'center', WhiteIndex(screenNumber));
        Screen('Flip', window);
        WaitSecs(2);

        %% Close Psychtoolbox
        ShowCursor;
        Priority(0);
        sca;

        %%%%%%% Error handling
        ShowCursor;
        Priority(0);
        sca;
        rethrow(ME);

    catch ME2
        %%%%%%% Error handling
        ShowCursor;
        Priority(0);
        sca;
        rethrow(ME2);
    end

end
