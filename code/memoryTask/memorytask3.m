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
    subjectDir = fullfile(currentDir, ['sub-', char(dat.subjctNumber)]);
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
    
    %% Experiment Instructions
    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Courier');
    DrawFormattedText(window, 'Press any key to begin...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);
    KbStrokeWait;
    
    %% Load Images and Order
    
    imageFolderl = fullfile(currentDir, 'leftImages');
    imageFolderr = fullfile(currentDir, 'rightImages');
    
    % Load .mat files 
    load('left.mat', 'left');
    load('right.mat', 'right');
    
    % List image files
    imageFilesl = dir(fullfile(imageFolderl, '*.jpg'));
    imageFilesr = dir(fullfile(imageFolderr, '*.jpg'));
    
    %check mat file
    if max(left) > numel(imageFilesl) || max(right) > numel(imageFilesr)
        error('The indices in left.mat or right.mat exceed the number of available images.');
    end
    
    numImages = numel(left); % Use the number of trials defined in left.mat/right.mat
    
    %% Preload images
    loadedImagesl = cell(1, numImages);
    loadedImagesr = cell(1, numImages);
    
    for i = 1:numImages
        
        imagePathl = fullfile(imageFolderl, imageFilesl(left(i)).name);
        imagePathr = fullfile(imageFolderr, imageFilesr(right(i)).name);
        
        theImagel = imread(imagePathl);
        theImager = imread(imagePathr);
        
        %% Resize images 
        % 50% of screen height
        resizedHeight = screenYpixels * 0.5; % 50% of screen height
        aspectRatioL = size(theImagel, 2) / size(theImagel, 1);
        aspectRatioR = size(theImager, 2) / size(theImager, 1);
        resizedWidthL = round(resizedHeight * aspectRatioL);
        resizedWidthR = round(resizedHeight * aspectRatioR);
        
        loadedImagesl{i} = imresize(theImagel, [resizedHeight, resizedWidthL]);
        loadedImagesr{i} = imresize(theImager, [resizedHeight, resizedWidthR]);
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
    
    %% Define positions for left and right images
    % 30% of screen width
    leftX = xCenter - screenXpixels * 0.3; 
    rightX = xCenter + screenXpixels * 0.3; 
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
                if keyCode(leftKey)
                    choice = 'L';
                elseif keyCode(rightKey)
                    choice = 'R';
                end
            end
            WaitSecs(0.01);
        end
        tEnd = GetSecs;

        %% Record response
        results{k, 1} = imageFilesl(left(k)).name; % Left image name
        results{k, 2} = imageFilesr(right(k)).name; % Right image name
        results{k, 3} = choice; % Choice (L or R)
        
        fprintf('Trial %d complete. Choice: %s, Reaction Time: %.2f s\n', k, choice, tEnd - tStart);
    end
    
    %% Save results
    fprintf('Saving results...\n');
    resultsFile = fullfile(subjectDir, ['results_sub-', char(dat.subjctNumber), '.mat']);
    save(resultsFile, 'results');
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
    %%%%%%% Error handling
    ShowCursor;
    Priority(0);
    sca;
    rethrow(ME);
end
