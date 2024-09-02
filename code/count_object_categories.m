% Define the path to the folder containing the image subfolders
baseFolder = 'C:\Users\JLU-SU\OneDrive - Justus-Liebig-Universität Gießen\Dokumente\GitHub\pep_wp4_eye_tracking\AOIs';

% Define the path to the Excel file with object categories and objects
excelFile = 'C:\Users\JLU-SU\OneDrive - Justus-Liebig-Universität Gießen\Dokumente\GitHub\pep_wp4_eye_tracking\similarities.xlsx';

% Read the excel file
 similarities = readtable(excelFile,'Format','auto');

% Extract categories and objects from the table
categories = similarities.Category;
objectColumns = similarities(:, 3:end);  % Extract all columns containing objects

% Get list of subfolders in baseFolder (each subfolder is an image)
imageFolders = dir(baseFolder);
imageFolders = imageFolders([imageFolders.isdir] & ~ismember({imageFolders.name}, {'.', '..'}));

% Initialize a count matrix to store how many images contain objects from each category
categoryCounts = zeros(height(similarities), 1);

% Loop over each image folder
for i = 1:length(imageFolders)
    % Get the folder path for the current image
    imageFolderPath = fullfile(baseFolder, imageFolders(i).name);
    
    % Get the list of mask files (objects) in the current image's folder
    maskFiles = dir(fullfile(imageFolderPath, '*.png'));
    maskFileNames = {maskFiles.name};  % Extract filenames
    
    % Loop through each category and check if any object from that category is in the current image's folder
    for categoryIdx = 1:height(similarities)
        % Get all objects that belong to the current category (non-empty values in the row)
        categoryObjects = table2cell(objectColumns(categoryIdx, :));
        categoryObjects = categoryObjects(~cellfun('isempty', categoryObjects)); % Remove empty cells
        
        % Check if any of the mask file names match any object in the current category
        for objIdx = 1:length(categoryObjects)
            objName = categoryObjects{objIdx};
            
            % Check if the object is in the mask file names
            if any(contains(maskFileNames, objName))
                % If any object from this category is present, increment the category count
                categoryCounts(categoryIdx) = categoryCounts(categoryIdx) + 1;
                break; % Move on to the next category once one object is found
            end
        end
    end
end

% Display the results
for categoryIdx = 1:length(categories)
    fprintf('Category "%s" is found in %d images.\n', categories{categoryIdx}, categoryCounts(categoryIdx));
end
