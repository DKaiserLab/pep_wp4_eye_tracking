sca;
close all;
clear;
%Screen('Preference', 'SkipSyncTests', 1);
%Set up some defult configurations for color, key names,...
PsychDefaultSetup(2);

 
%% set up
dat.subjctNumber=input('Enter subject number: '); 
dat.age=input('Enter subject age: '); 
dat.gender=input('Enter subject gender (1=M, 2=F, 3=D): '); 

dat.filename=['test','_s',num2str(dat.subjctNumber)];
%display(dat.filename);

 %% Save the data
save(dat.filename, 'dat');


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

%frame duration %% when I use frame duration, the timing is not accurate!!!
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
%for the images
%waitframes3 = round(presentation_time / ifi);
%for cross fixation
%waitframes1 = round(1 / ifi);
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
    % Initialize keyboard
    KbName('UnifyKeyNames');
    abortKey = KbName('ESCAPE');
    
    % Loop through each image file
    for i = 1:NumImage
        % Check for keyboard input
        [~, ~, keyCode] = KbCheck;
        % If abort key is pressed, terminate the program
        if keyCode(abortKey)
            error('Experiment has been aborted');
        end

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
        %Flip to the screen
        vbl = Screen('Flip', window);
      
        % Wait for the specified duration
        % start timer
        elapsedTime = 0;
        start_time = GetSecs;
        while elapsedTime < (presentation_time - frame_duration * 0.5)
            % option to abort experiment 
            [~, ~, Resp1] = KbCheck;
            if  Resp1(abortKey)
                error('Experiment has been aborted');
            end
            % updating clock:
            elapsedTime = GetSecs - start_time;
        end

        % Close the texture to free memory
        Screen('Close', imageTexture);
        
        % Draw the fixation cross in 
        Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
        % Flip to the screen
        vbl = Screen('Flip', window);
        % Wait for 1 second
        WaitSecs(1);

        % Practice session 
        if i == 3
            DrawFormattedText(window, '...The end of the Practice session...', 'center', screenYpixels * 0.25, white);
            % Update the window to display the drawn text
            vbl = Screen('Flip', window);
            KbStrokeWait;
        end

        % Break ( it's an Example)
        if i == 5
            DrawFormattedText(window, '...Break...', 'center', screenYpixels * 0.25, white);
            % Update the window to display the drawn text
            vbl = Screen('Flip', window);
            KbStrokeWait;
        end
        
    end 
    sca;
catch
    sca;
    psychrethrow(psychlasterror);
end