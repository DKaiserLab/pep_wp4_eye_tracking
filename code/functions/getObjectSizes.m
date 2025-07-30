function avgObjSize = getObjectSizes(category)

% get object sizes
load(fullfile(pwd, '..', 'ObjectSizes.mat'));

% get object category memberships
objCategoryFileAll = readtable(fullfile(pwd, '..', 'objectCategories.xlsx'),'Format','auto');
objCategoryFile = objCategoryFileAll(objCategoryFileAll.([category, 'Frequency']) >= 10, :);

% get mean proportional size of object categories
objectSizeCate = nan(length(ObjSize.(category)), height(objCategoryFile));
for iImg = 1:length(ObjSize.(category))
    for iObjCate = 1:height(objCategoryFile)

        % check if any object belong to current object category
        cateObjects = ismember(ObjSize.(category)(iImg).object, table2cell(objCategoryFile(iObjCate, 4:end)));
        if sum(cateObjects) == 0
            continue
        end
        % get sum of over all object sizes of that category
        objectSizeCate(iImg, iObjCate) = sum(ObjSize.(category)(iImg).propSize(cateObjects));
    end
end

% take mean
avgObjSize = mean(objectSizeCate, 1, 'omitnan');
end