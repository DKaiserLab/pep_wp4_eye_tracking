
array = [data.gaze.systemTimeStamp];

figure;

gaze_x = data.gaze.right.gazePoint.onDisplayArea(1,:);
gaze_y = data.gaze.right.gazePoint.onDisplayArea(2,:);

hold on
plot(1:numel(gaze_x),gaze_x, 'g')
plot(1:numel(gaze_y),gaze_y,'b')

for msg = 1:length(messages)
    if contains(messages{msg,2}, 'STIM ON')
        tp_msg = cell2mat(messages(msg,1));
        % Calculate the absolute differences
        differences = abs(array - tp_msg);
        % Find the index of the minimum difference
        [~, closestIndex] = min(differences);

        line([closestIndex,closestIndex],[0,1])
        line([closestIndex,closestIndex],[0,1],'Color','magenta')
        line([closestIndex+360,closestIndex+360],[0,1],'Color','magenta','LineStyle','--')
    end
end
hold off 