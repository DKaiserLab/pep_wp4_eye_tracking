% define folder where annotations are stored 
home_annotations = 'C:\Users\JLU-SU\OneDrive - Justus-Liebig-Universität Gießen\Dokumente\GitHub\pep_wp4_eye_tracking\stimuli\annotations';
cd(home_annotations)
no_anno = [];

D = LMdatabase(home_annotations);

% Loop through all images in the annotation struct
for i = 1:length(D)

    % show report
    disp(['Processing iamge: ', D(i).annotation.filename])

    % Initialize a map to store masks for each object
    object_masks = containers.Map;

    % make folder for this image
    image_folder = fullfile(home_annotations, '..', '..', 'AOIs', D(i).annotation.filename);
    if ~isfolder(image_folder)
        mkdir(image_folder);
    end

    % make copy of iumage to its folder 
    cd(image_folder)
    copyfile(fullfile(home_annotations, '..', D(i).annotation.filename));

    % Get the size of the original image
    if isfield(D(i).annotation, 'imagesize')
    img_size = [str2double(D(i).annotation.imagesize.nrows), str2double(D(i).annotation.imagesize.ncols)];
    else
      img = imread(D(i).annotation.filename);
      [nrows,ncols] = size(img);
      img_size = [nrows,ncols]; 
    end 

    if ~isfield(D(i).annotation, 'object')
        % show report
        warning(['Has no object annotations: ', D(i).annotation.filename])
        no_anno{end+1} = D(i).annotation.filename;
        continue
    end

    % Loop through all objects in the image
    for j = 1:length(D(i).annotation.object)
        obj = D(i).annotation.object(j);
        
        % Check if the object has a 'ispartof' field under parts
        if isfield(obj, 'parts') && isfield(obj.parts, 'ispartof') && ~isempty(obj.parts.ispartof)
            continue; % Skip objects that are part of another object
        end
        
        % Get the name of the object
        obj_name = obj.name;
        
        % Initialize mask if the object is encountered for the first time
        if ~isKey(object_masks, obj_name)
            object_masks(obj_name) = zeros(img_size);
        end
        
        % Get the mask for this object
        mask = object_masks(obj_name);
        
        % Loop through all polygons for this object
        for k = 1:length(obj.polygon)
            poly = obj.polygon(k);
            
            % Extract x and y coordinates from the polygon
            x = double(poly.x);
            y = double(poly.y);
            
            % Create a binary mask for the polygon
            poly_mask = poly2mask(x, y, img_size(1), img_size(2));
            
            % Combine the polygon mask with the object mask using OR operation
            mask = mask | poly_mask;
        end
        
        % Update the object mask in the map
        object_masks(obj_name) = mask;
    end
    
    % Save each object mask as a .png file
    mask_keys = keys(object_masks);
    for k = 1:length(mask_keys)
        obj_name = mask_keys{k};
        mask = object_masks(obj_name);
        
        % Save the mask as a .png file
        imwrite(mask, [obj_name, '.png']);
    end
end