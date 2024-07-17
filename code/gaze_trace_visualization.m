%% load subject
subject = 222;
file_name = fullfile('..', 'sourcedata',['sub-',num2str(subject)],['sub-',num2str(subject),'_task-EyeTracking_physio.mat']);
load(file_name)

%% get event timing
time_array = double([data.gaze.systemTimeStamp]);
time_array_s = (time_array - time_array(1))/10^6;

%% plotting

figure;

gaze_x = data.gaze.right.gazePoint.onDisplayArea(1,:);
gaze_y = data.gaze.right.gazePoint.onDisplayArea(2,:);

% Set the color and transparency of the bars
barColor = [0.3, 0.3, 0.3];
barTransparency = 0.3; % Transparency (0 is fully transparent, 1 is fully opaque)
barHeight = [0, 1];
presentation_duration = 3;

hold on
plot(time_array_s,gaze_x, 'g')
plot(time_array_s,gaze_y,'b')

for msg = 1:length(messages)
    if contains(messages{msg,2}, 'STIM ON')

        % get timepoint of message
        tp_msg = cell2mat(messages(msg,1));
        tp_msg_s = (tp_msg - time_array(1))/10^6;

        % get time point of next message ('STIM OFF')
        tp_nxt_msg = cell2mat(messages(msg+1,1));
        tp_nxt_msg_s = (tp_nxt_msg - time_array(1))/10^6;

        % get time point of previous message ('SPACE PRESS')
        tp_prev_msg = cell2mat(messages(msg-1,1));
        tp_prev_msg_s = (tp_prev_msg - time_array(1))/10^6;

        % make lines of events
        line([tp_msg_s,tp_msg_s],[barHeight(1), barHeight(2)],'Color','black')
        line([tp_nxt_msg_s,tp_nxt_msg_s],[barHeight(1), barHeight(2)],'Color','black','LineStyle','--')
        line([tp_prev_msg_s,tp_prev_msg_s],[barHeight(1), barHeight(2)],'Color',barColor,'LineStyle','--')

        % make bar for duration of stimulus present
        xBar = [tp_msg_s, tp_msg_s,tp_nxt_msg_s,tp_nxt_msg_s];
        yBar = [barHeight(1), barHeight(2), barHeight(2), barHeight(1)];
        patch(xBar, yBar, barColor, 'FaceAlpha', barTransparency, 'EdgeColor', 'none');

    end
end

hold off 



