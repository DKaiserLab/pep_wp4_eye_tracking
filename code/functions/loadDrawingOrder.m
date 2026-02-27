function [d, cfg] = loadDrawingOrder(cfg, d)

if ~isfield(cfg, 'minNumPerCate'); cfg.minNumPerCate = 15; end

% get drawing order file
drawingOrder = readtable(fullfile(pwd, '..',...
    ['DrawingOrder', [upper(cfg.exp_name(1)), cfg.exp_name(2:end)],...
    '.xlsx']),'Format','auto');
allObjects = table2cell(drawingOrder(:, 3:end));

% % get unique objects
% realObjects = reshape(allObjects, [1, numel(allObjects(:, 2:end))]);
% realObjects = ones(1, numel(realObjects));
% for o = 1:numel(allObjects)
%     if isempty(allObjects{o}) || all(isnan(allObjects{o}))
%         realObjects(o) = 0;
%     end
% end
%
% allObjects = allObjects(logical(realObjects));
% uniqueObjects = unique(allObjects);
%
% outputFile = fullfile(pwd, 'unqiueOrder.csv');
% writecell(uniqueObjects, outputFile);

% loop thorufh scene categories
for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    % scene category objects
    cateObjects = allObjects(strcmpi(category, allObjects(:,1)), 2:end);

    % get object category memberships
    objCategoryFileAll = readtable(fullfile(pwd, '..', 'objectCategories.xlsx'),'Format','auto');
    objCategoryFile = objCategoryFileAll(objCategoryFileAll.([category, 'Frequency']) >= cfg.minNumPerCate, :);

    % init result table
    orderTable = nan(cfg.n, height(objCategoryFile));

    % loop through subjects and drawn objects
    for iSub = 1:cfg.n
        for iObj = 1:width(cateObjects)

            % skip if no object or category has been drawn already
            if isempty(cateObjects{iSub,iObj})
                continue
            end

            % find object in object category file
            objectName = cateObjects{iSub,iObj};
            objIdx = strcmp(table2cell(objCategoryFile), objectName);
            cateIdx = find(sum(objIdx, 2));

            % write drawing order to results table
            if isnan(orderTable(iSub,cateIdx))
                orderTable(iSub,cateIdx) = iObj;
            end
        end
    end

    % write to data struct
    d.drawingOrder.(category).table = orderTable;
    cfg.(['categoriesNames_', category]) = objCategoryFile.Category';

end
end