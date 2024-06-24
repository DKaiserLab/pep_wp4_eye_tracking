sca;
close all;
clearvars;

%Psychtoolbox Defaults
%Here we call some default settings for setting up Psychtoolbox

PsychDefaultSetup(2);

%Skip sync tests

Screen('Preference', 'SkipSyncTests', 1);

%Get EyeTracker
Tobii = EyeTrackingOperations();

eyetrackers = Tobii.find_all_eyetrackers;
eyetracker_address = eyetrackers(1).Address;
% Example:
% eyetracker_address = 'tet-tcp://172.28.195.1';

eyetracker = Tobii.get_eyetracker(eyetracker_address);

if isa(eyetracker,'EyeTracker')
    disp(['Address:',eyetracker.Address]);
    disp(['Name:',eyetracker.Name]);
    disp(['Serial Number:',eyetracker.SerialNumber]);
    disp(['Model:',eyetracker.Model]);
    disp(['Firmware Version:',eyetracker.FirmwareVersion]);
    disp(['Runtime Version:',eyetracker.RuntimeVersion]);
else
    disp('Eye tracker not found!');
end

%Select Screen
%Get the screen numbers. This gives us a number for each of the screens attached to our computer. For help see: Screen Screens?

screens = Screen('Screens');

% So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen. When only one screen is attached to the monitor we will draw to
% this. For help see: help max
screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% luminace values are (in general) defined between 0 and 1.
% For help see: help WhiteIndex and help BlackIndex
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

% Open an on screen window and color it black.
% For help see: Screen OpenWindow?
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

% Get the size of the on screen window in pixels.
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
screen_pixels = [screenXpixels screenYpixels];

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Enable alpha blending for anti-aliasing
% For help see: Screen BlendFunction?
% Also see: Chapter 6 of the OpenGL programming guide

Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

%Track Status
%Show on screen the position of the user's eyes to garantee that the user is positioned correctly in the tracking area.

% Dot size in pixels
dotSizePix = 30;

%% Start collecting data
% The subsequent calls return the current values in the stream buffer.
% If a flat structure is prefered just use an extra input 'flat'.
% i.e. gaze_data = eyetracker.get_gaze_data('flat');
eyetracker.get_gaze_data();

Screen('TextSize', window, 20);

while ~KbCheck

    DrawFormattedText(window, 'When correctly positioned press any key to start the calibration.', 'center', screenYpixels * 0.1, white);

    distance = [];

    gaze_data = eyetracker.get_gaze_data();

    if ~isempty(gaze_data)
        last_gaze = gaze_data(end);

        validityColor = [1 0 0];

        % Check if user has both eyes inside a reasonable tacking area.
        if last_gaze.LeftEye.GazeOrigin.Validity.Valid && last_gaze.RightEye.GazeOrigin.Validity.Valid
            left_validity = all(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) < 0.85) ...
                && all(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) > 0.15);
            right_validity = all(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) < 0.85) ...
                && all(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1:2) > 0.15);
            if left_validity && right_validity
                validityColor = [0 1 0];
            end
        end

        origin = [screenXpixels/4 screenYpixels/4];
        size = [screenXpixels/2 screenYpixels/2];

        penWidthPixels = 3;
        baseRect = [0 0 size(1) size(2)];
        frame = CenterRectOnPointd(baseRect, screenXpixels/2, yCenter);

        Screen('FrameRect', window, validityColor, frame, penWidthPixels);

        % Left Eye
        if last_gaze.LeftEye.GazeOrigin.Validity.Valid
            distance = [distance; round(last_gaze.LeftEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
            left_eye_pos_x = double(1-last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(1))*size(1) + origin(1);
            left_eye_pos_y = double(last_gaze.LeftEye.GazeOrigin.InTrackBoxCoordinateSystem(2))*size(2) + origin(2);
            Screen('DrawDots', window, [left_eye_pos_x left_eye_pos_y], dotSizePix, validityColor, [], 2);
        end

        % Right Eye
        if last_gaze.RightEye.GazeOrigin.Validity.Valid
            distance = [distance;round(last_gaze.RightEye.GazeOrigin.InUserCoordinateSystem(3)/10,1)];
            right_eye_pos_x = double(1-last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(1))*size(1) + origin(1);
            right_eye_pos_y = double(last_gaze.RightEye.GazeOrigin.InTrackBoxCoordinateSystem(2))*size(2) + origin(2);
            Screen('DrawDots', window, [right_eye_pos_x right_eye_pos_y], dotSizePix, validityColor, [], 2);
        end
        pause(0.05);
    end

    DrawFormattedText(window, sprintf('Current distance to the eye tracker: %.2f cm.',mean(distance)), 'center', screenYpixels * 0.85, white);


    % Flip to the screen. This command basically draws all of our previous
    % commands onto the screen.
    % For help see: Screen Flip?
    Screen('Flip', window);

end

eyetracker.stop_gaze_data();

%% Calibration
spaceKey = KbName('Space');
RKey = KbName('R');

dotSizePix = 30;

dotColor = [[1 0 0];[1 1 1]]; % Red and white

leftColor = [1 0 0]; % Red
rightColor = [0 0 1]; % Bluesss

% Calibration points
lb = 0.1;  % left bound
xc = 0.5;  % horizontal center
rb = 0.9;  % right bound
ub = 0.1;  % upper bound
yc = 0.5;  % vertical center
bb = 0.9;  % bottom bound

points_to_calibrate = [[lb,ub];[rb,ub];[xc,yc];[lb,bb];[rb,bb]];

% Create calibration object
calib = ScreenBasedCalibration(eyetracker);

calibrating = true;

while calibrating
    % Enter calibration mode
    calib.enter_calibration_mode();

    for i=1:length(points_to_calibrate)

        Screen('DrawDots', window, points_to_calibrate(i,:).*screen_pixels, dotSizePix, dotColor(1,:), [], 2);
        Screen('DrawDots', window, points_to_calibrate(i,:).*screen_pixels, dotSizePix*0.5, dotColor(2,:), [], 2);

        Screen('Flip', window);

        % Wait a moment to allow the user to focus on the point
        pause(1);

        if calib.collect_data(points_to_calibrate(i,:)) ~= CalibrationStatus.Success
            % Try again if it didn't go well the first time.
            % Not all eye tracker models will fail at this point, but instead fail on ComputeAndApply.
            calib.collect_data(points_to_calibrate(i,:));
        end

    end

    DrawFormattedText(window, 'Calculating calibration result....', 'center', 'center', white);

    Screen('Flip', window);

    % Blocking call that returns the calibration result
    calibration_result = calib.compute_and_apply();

    calib.leave_calibration_mode();

    if calibration_result.Status ~= CalibrationStatus.Success
        break
    end

    % Calibration Result

    points = calibration_result.CalibrationPoints;

    for i=1:length(points)
        Screen('DrawDots', window, points(i).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.5, dotColor(2,:), [], 2);
        for j=1:length(points(i).RightEye)
            if points(i).LeftEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('DrawDots', window, points(i).LeftEye(j).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.3, leftColor, [], 2);
                Screen('DrawLines', window, ([points(i).LeftEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*screen_pixels)', 2, leftColor, [0 0], 2);
            end
            if points(i).RightEye(j).Validity == CalibrationEyeValidity.ValidAndUsed
                Screen('DrawDots', window, points(i).RightEye(j).PositionOnDisplayArea.*screen_pixels, dotSizePix*0.3, rightColor, [], 2);
                Screen('DrawLines', window, ([points(i).RightEye(j).PositionOnDisplayArea; points(i).PositionOnDisplayArea].*screen_pixels)', 2, rightColor, [0 0], 2);
            end
        end

    end

    DrawFormattedText(window, 'Press the ''R'' key to recalibrate or ''Space'' to continue....', 'center', screenYpixels * 0.95, white)

    Screen('Flip', window);

    while 1.
        [ keyIsDown, seconds, keyCode ] = KbCheck;
        keyCode = find(keyCode, 1);

        if keyIsDown
            if keyCode == spaceKey
                calibrating = false;
                break;
            elseif keyCode == RKey
                break;
            end
            KbReleaseWait;
        end
    end
end



%Simple data colecting experiment
pointCount = 5;

% Generate an array with coordinates of random points on the display area
rng;
points = rand(pointCount,2);

% Start to collect data
eyetracker.get_gaze_data();

collection_time_s = 2; % seconds

% % Cell array to store events
% events = cell(2, pointCount);
% 
% 
% for i=1:pointCount
%     Screen('DrawDots', window, points(i,:).*screen_pixels, dotSizePix, dotColor(2,:), [], 2);
%     Screen('Flip', window);
%     % Event when startng to show the stimulus
%     events{1,i} = {Tobii.get_system_time_stamp, points(i,:)};
%     pause(collection_time_s);
%     % Event when stopping to show the stimulus
%     events{2,i} = {Tobii.get_system_time_stamp, points(i,:)};
% end

% Dot properties
dotSize = 10;
% Initialize variables to store gaze data
gazeDataLeftEyeX = [];
gazeDataLeftEyeY = [];
gazeDataRightEyeX = [];
gazeDataRightEyeY = [];
timestamps = [];


% Retreive data collected during experiment
collected_gaze_data = eyetracker.get_gaze_data();
pause(0.3);

while ~KbCheck

    gaze_data = eyetracker.get_gaze_data();

    if ~isempty(gaze_data)
        last_gaze = gaze_data(end);

        if ~isnan(last_gaze.LeftEye.GazePoint.OnDisplayArea(1))
            timestamp = Tobii.get_system_time_stamp;

            % Left Eye
            leftEyeX = double(last_gaze.LeftEye.GazePoint.OnDisplayArea(1)) * screenXpixels;
            leftEyeY = double(last_gaze.LeftEye.GazePoint.OnDisplayArea(2)) * screenYpixels;

            % Right Eye
            rightEyeX = double(last_gaze.RightEye.GazePoint.OnDisplayArea(1)) * screenXpixels;
            rightEyeY = double(last_gaze.RightEye.GazePoint.OnDisplayArea(2)) * screenYpixels;

            % Append the gaze data and timestamp to the arrays
            gazeDataLeftEyeX = [gazeDataLeftEyeX, leftEyeX];
            gazeDataLeftEyeY = [gazeDataLeftEyeY, leftEyeY];
            gazeDataRightEyeX = [gazeDataRightEyeX, rightEyeX];
            gazeDataRightEyeY = [gazeDataRightEyeY, rightEyeY];
            timestamps = [timestamps, timestamp];

            Screen('FillRect', window, [0 0 0]); % Clear screen
            Screen('FillOval', window, [0 1 0], [leftEyeX - dotSize / 2, leftEyeY - dotSize / 2, leftEyeX + dotSize / 2, leftEyeY + dotSize / 2]); % Green dot for left eye
            Screen('FillOval', window, [0 0 1], [rightEyeX - dotSize / 2, rightEyeY - dotSize / 2, rightEyeX + dotSize / 2, rightEyeY + dotSize / 2]); % Blue dot for right eye
            Screen('Flip', window);

            pause(0.05);
            Screen('Flip', window);
        end
    end

end

eyetracker.stop_gaze_data();
%Clear

sca;

% Save the data to an HDF5 file
hdf5FileName = 'gaze_data.h5';

% Create and write all datasets in one HDF5 file
h5create(hdf5FileName, '/timestamps', numel(timestamps));
h5write(hdf5FileName, '/timestamps', timestamps);

h5create(hdf5FileName, '/gazeDataLeftEyeX', numel(gazeDataLeftEyeX));
h5write(hdf5FileName, '/gazeDataLeftEyeX', gazeDataLeftEyeX);

h5create(hdf5FileName, '/gazeDataLeftEyeY', numel(gazeDataLeftEyeY));
h5write(hdf5FileName, '/gazeDataLeftEyeY', gazeDataLeftEyeY);

h5create(hdf5FileName, '/gazeDataRightEyeX', numel(gazeDataRightEyeX));
h5write(hdf5FileName, '/gazeDataRightEyeX', gazeDataRightEyeX);

h5create(hdf5FileName, '/gazeDataRightEyeY', numel(gazeDataRightEyeY));
h5write(hdf5FileName, '/gazeDataRightEyeY', gazeDataRightEyeY);

disp('Gaze data has been saved to a single HDF5 file.');

%Clear the screen. "sca" is short hand for "Screen CloseAll". This clears all features related to PTB. Note: we leave the variables in the workspace so you can have a look at them if you want. For help see: help sca

