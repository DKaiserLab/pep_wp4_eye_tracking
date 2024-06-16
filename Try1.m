sca;
close all;
clear;
Screen('Preference', 'SkipSyncTests', 1);
PsychDefaultSetup(2);

%% Set up
dat.subjctNumber = input('Enter subject number: ');
dat.age = input('Enter subject age: ');
dat.gender = input('Enter subject gender (1=M, 2=F, 3=D): ');

dat.filename = ['test', '_s', num2str(dat.subjctNumber)];

% Save the data
save(dat.filename, 'dat');

% Returns an array of screen numbers available on the system
screens = Screen('Screens');
screenNumber = max(screens);

black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Get the size of the screen
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Frame duration
frame_duration = Screen('GetFlipInterval', window);

% Center of the window
[xCenter, yCenter] = RectCenter(windowRect);

%% Instruction of the experiment
Screen('TextSize', window, 70);
Screen('TextFont', window, 'Courier');
DrawFormattedText(window, '...Explanation...', 'center', screenYpixels * 0.25, white);
Screen('Flip', window);
KbStrokeWait;

%% Image
% Folder containing the images
imageFolder = fullfile(pwd, 'Images'); 
% List of all image files in the folder
imageFiles = dir(fullfile(imageFolder, '*.jpg')); 
numImages = numel(imageFiles);
% Number of repetitions for each image
numRepeats = 3;
% presentation time for each image (in seconds)
presentation_time = 3; 

%% Fixation Cross
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
lineWidthPix = 4;

%% Preload and resize images
%width
resizedWidth = 0.5 * screenXpixels; 
%height
resizedHeight = 0.5 * screenYpixels;  
loadedImages = cell(1, numImages);
for i = 1:numImages
    imagePath = fullfile(imageFolder, imageFiles(i).name);
    theImage = imread(imagePath);
    % Resize the image to the desired size
    resizedImage = imresize(theImage, [resizedHeight, resizedWidth]); 
    loadedImages{i} = resizedImage;
end

% Create textures for the images
imageTextures = cell(1, numImages);
for i = 1:numImages
    imageTextures{i} = Screen('MakeTexture', window, loadedImages{i});
end

%% Prepare the log file
logFilename = [dat.filename, '_log.txt'];
logFile = fopen(logFilename, 'w');
fprintf(logFile, 'Trial\tImage\tImageFlipTime\tFixationFlipTime\n');

%% Generate the trial sequence
trialSequence = [];
for i = 1:numRepeats
    trialSequence = [trialSequence randperm(numImages)];
end

%% Ensure no consecutive repeats
while any(diff(trialSequence) == 0)
    trialSequence = [];
    for i = 1:numRepeats
        trialSequence = [trialSequence randperm(numImages)];
    end
end
%%
try
    %% Initialize keyboard
    
    KbName('UnifyKeyNames');% for different devices
    abortKey = KbName('ESCAPE');

    % loop through the images
    trial = 1;
    for i = 1:length(trialSequence)
        %% Check for keyboard input
        [~, ~, keyCode] = KbCheck;
        if keyCode(abortKey)
            error('Experiment has been aborted');
        end

        %% Get the current image index
        imageIndex = trialSequence(i);

        % Display the image
        Screen('DrawTexture', window, imageTextures{imageIndex});
        imageFlipTime = Screen('Flip', window);

        %% Wait for the specified duration
        elapsedTime = 0;
        start_time = GetSecs;
        while elapsedTime < (presentation_time - frame_duration * 0.5)
            [~, ~, keyCode] = KbCheck;
            % check again for key press
            if keyCode(abortKey)
                error('Experiment has been aborted');
            end
            elapsedTime = GetSecs - start_time;
        end

        %% Draw the fixation cross
        Screen('DrawLines', window, allCoords, lineWidthPix, white, [xCenter yCenter], 2);
        fixationFlipTime = Screen('Flip', window);
        WaitSecs(1);

        %% Log the trial information
        fprintf(logFile, '%d\t%s\t%.4f\t%.4f\n', trial, imageFiles(imageIndex).name, imageFlipTime, fixationFlipTime);

        %% Practice session
        if trial == 3
            DrawFormattedText(window, '...The end of the Practice session...', 'center', screenYpixels * 0.25, white);
            Screen('Flip', window);
            KbStrokeWait;
        end

        %% Break (it's an example)
        % remember: we have to add more breaks!
        if trial == 5
            DrawFormattedText(window, '...Break...', 'center', screenYpixels * 0.25, white);
            Screen('Flip', window);
            KbStrokeWait;
        end

        trial = trial + 1;
    end
    sca;
    fclose(logFile);
catch
    sca;
    fclose(logFile);
    psychrethrow(psychlasterror);
end
