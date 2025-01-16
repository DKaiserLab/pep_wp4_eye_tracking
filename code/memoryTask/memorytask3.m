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
    
    %% Experiment Instructions
    Screen('TextSize', window, 40);
    Screen('TextFont', window, 'Courier');
    DrawFormattedText(window, 'Press any key to begin...', 'center', screenYpixels * 0.25, WhiteIndex(screenNumber));
    Screen('Flip', window);
    KbStrokeWait;
    
   % Load .mat files
load('left.mat', 'left');
load('right.mat', 'right');

% Validate the loaded variables
if ~exist('left', 'var')
    error('The variable "left" was not found in left.mat.');
end
if ~exist('right', 'var')
    error('The variable "right" was not found in right.mat.');
end

% Load image files
imageFilesl = dir(fullfile('leftImages', '*.jpg'));
imageFilesr = dir(fullfile('rightImages', '*.jpg'));

% Sort files by name to ensure correct order
[~, idxl] = sort({imageFilesl.name});
[~, idxr] = sort({imageFilesr.name});
imageFilesl = imageFilesl(idxl);
imageFilesr = imageFilesr(idxr);

% Debug: Print sorted filenames to check order
disp('Sorted filenames in leftImages:');
disp({imageFilesl.name});
disp('Sorted filenames in rightImages:');
disp({imageFilesr.name});

% Check if indices in left.mat and right.mat are valid
if max(left) > numel(imageFilesl)
    error('Index in left.mat exceeds the number of images in leftImages.');
end
if max(right) > numel(imageFilesr)
    error('Index in right.mat exceeds the number of images in rightImages.');
end

% Preload images
numImages = numel(left); % Number of trials from left.mat
loadedImagesl = cell(1, numImages);
loadedImagesr = cell(1, numImages);

for i = 1:numImages
    % File paths using indices from left.mat and right.mat
    imagePathl = fullfile('leftImages', imageFilesl(left(i)).name);
    imagePathr = fullfile('rightImages', imageFilesr(right(i)).name);

    % Debug: Print mappings for verification
    fprintf('Trial %d: Loading left image: %s (Index %d)\n', i, imageFilesl(left(i)).name, left(i));
    fprintf('Trial %d: Loading right image: %s (Index %d)\n', i, imageFilesr(right(i)).name, right(i));

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
