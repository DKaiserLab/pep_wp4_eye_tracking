 

%%%
% Define the folder containing images
initialFolder = fullfile(pwd, 'rightImages'); 

% Check if the folder exists
if ~exist(initialFolder, 'dir')
    error('The folder %s does not exist.', initialFolder);
end

% List of all images
imageFiles = dir(fullfile(initialFolder, '*.jpg')); 

% Check if there are any images
if isempty(imageFiles)
    error('No .jpg images found in the folder %s.', initialFolder);
end

% Extract the names of the images
imageNames = {imageFiles.name};
numImages = numel(imageNames);  % Ensure this matches the number of images found
right = randperm(numImages); 

% Save the random order to a .mat file
matFileName = 'right';
save(matFileName, 'right'); 

% Specify the text file name for saving image names
textFileName = 'image_names.txt';

% Open the file for writing
fileID = fopen(textFileName, 'w');
if fileID == -1
    error('Cannot open file %s for writing.', textFileName);
end

% Write each image name to the file
for i = 1:numImages
    fprintf(fileID, '%s\n', imageNames{i});
end

% Close the file
fclose(fileID);

disp('Files have been created successfully.');
