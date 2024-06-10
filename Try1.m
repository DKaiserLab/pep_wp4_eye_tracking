sca;
close all;
clear;
% I have to remove it
Screen('Preference', 'SkipSyncTests', 1);
%Set up some defult configurations for color, key names,...
PsychDefaultSetup(2);

% returns an array of screen numbers available on the system
screens = Screen('Screens');
screenNumber = 0;

black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

%Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%get the size
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

%frame duration
frame_duration = Screen('GetFlipInterval', window);

% center of the window
[xCenter, yCenter] = RectCenter(windowRect);


%% Instruction of the experiment
%Draw text 
Screen('TextSize', window, 70);
Screen('TextFont', window, 'Courier');
DrawFormattedText(window, '...Explanation...', 'center', screenYpixels * 0.25, white);
%Update the window to display the drawn text
Screen('Flip', window);
% Press 'Enter' to continue. THERE is an error when I use this one :(
% KbWait([], KbName('return'));
    %(I have to try this one: KbWait([], 2);
KbStrokeWait;
%% Image
% Folder containing the images
imageFolder = fullfile(pwd, 'Images'); % pwd: Uses the current directory
% Get a list of all image files in the folder
imageFiles = dir(fullfile(imageFolder, '*.jpg'));

% Set the presentation time for each image (in seconds)
presentation_time = 3;
waitframes = round(presentation_time / frame_duration);
%% Fixation Cross
%size and position of the cross fixation
fixCrossDimPix = 40;
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];
%line width
lineWidthPix = 4;

NumImage = numel(imageFiles);
try
    % Loop through each image file
    for i = 1:NumImage
        % Load the image
        imagePath = fullfile(imageFolder, imageFiles(i).name);
        theImage = imread(imagePath);
        % Resize the image to the desired size
        resizedImage = imresize(theImage, [0.5 * screenYpixels, 0.5 * screenXpixels]);
        % Get the size of the resized image
        [s1, s2, ~] = size(resizedImage);
        
        % Create a destination rectangle to center the image on the screen
        dstRect = [xCenter - s2/2, yCenter - s1/2, xCenter + s2/2, yCenter + s1/2];
        % Display the image on the screen
        imageTexture = Screen('MakeTexture', window, resizedImage);
        % Draw the texture to the screen
        Screen('DrawTexture', window, imageTexture);

        % (before)Get an initial screen flip for timing
        %(now) flip the screen
        vbl = Screen('Flip', window);
       
        % (before)Flip to the screen
        %vbl  = Screen('Flip', window, vbl + (waitframes - 0.5) * frame_duration);
        
        % Wait for the specified duration
        WaitSecs(presentation_time);
        % Close the texture to free memory
        Screen('Close', imageTexture);
        
       %%
       % Draw the fixation cross in 
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       % Flip to the screen
       Screen('Flip', window);
       % Wait for 1 second
       WaitSecs(1);
       %% Break ( it's an Example)
        if i == 2
            DrawFormattedText(window, '...Break...', 'center', screenYpixels * 0.25, white);
            %Update the window to display the drawn text
            Screen('Flip', window);
            KbStrokeWait;
        end
    end 
    sca;
catch
     sca;
    psychrethrow(psychlasterror);
end