% Define the path to the folder containing the image subfolders
aoiFolder = fullfile(pwd, '..', 'AOIs');

% Define the path to the Excel file with object categories and objects
objectCategoriesFile = fullfile(pwd, '..', 'objectCategories.xlsx');
imageCategoriesFile = fullfile(pwd, '..', 'imageCategories.csv');

% Read the excel file
objectCategories = readtable(objectCategoriesFile,'Format','auto');
imageCategories = readtable(imageCategoriesFile,'Format','auto');

% set counters to 0
objectCategories.bathroomFrequency = zeros(height(objectCategories), 1);
objectCategories.kitchenFrequency = zeros(height(objectCategories), 1);

% Extract categories and objects from the table
categories = objectCategories.Category;
objectColumns = objectCategories(:, 4:end);  % Extract all columns containing objects

% Get list of subfolders in baseFolder (each subfolder is an image)
imageFolders = dir(fullfile(aoiFolder, '*.jpg'));
imageFolders = imageFolders([imageFolders.isdir] & ~ismember({imageFolders.name}, {'.', '..'}));

% Loop over each image folder
for i = 1:length(imageFolders)
    % Get the folder path for the current image
    imageFolderPath = fullfile(aoiFolder, imageFolders(i).name);

    % Get image category
    imageCategory = imageCategories{i, 2};

    % Get the list of mask files (objects) in the current image's folder
    maskFiles = dir(fullfile(imageFolderPath, '*.png'));
    maskFileNames = {maskFiles.name};  % Extract filenames
    
    % Loop through each category and check if any object from that category is in the current image's folder
    for categoryIdx = 1:height(objectCategories)
        % Get all objects that belong to the current category (non-empty values in the row)
        categoryObjects = table2cell(objectColumns(categoryIdx, :));
        categoryObjects = categoryObjects(~cellfun('isempty', categoryObjects)); % Remove empty cells
        
        % Check if any of the mask file names match any object in the current category
        for objIdx = 1:length(categoryObjects)
            objName = categoryObjects{objIdx};
            
            % Check if the object is in the mask file names
            if any(strcmp(maskFileNames, [objName, '.png']))

                % If any object from this category is present, increase the category count
                objectCategories.([char(imageCategory), 'Frequency'])(categoryIdx) = ...
                    objectCategories.([char(imageCategory), 'Frequency'])(categoryIdx) + 1;

                break; % Move on to the next category once one object is found
            end
        end
    end
end

% Write csv
writetable(objectCategories, objectCategoriesFile);
