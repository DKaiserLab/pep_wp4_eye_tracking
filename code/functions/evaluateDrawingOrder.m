drawingOrder = readtable(fullfile(pwd, '..', 'DrawingOrderExp1.xlsx'),'Format','auto');
allObjects = table2cell(drawingOrder(:, 4:end));
allObjects = reshape(allObjects, [1, numel(allObjects)]);

realObjects = ones(1, numel(allObjects));
for o = 1:numel(allObjects)
    if isempty(allObjects{o}) || all(isnan(allObjects{o}))
        realObjects(o) = 0;
    end
end

allObjects = allObjects(logical(realObjects));
uniqueObjects = unique(allObjects);

outputFile = fullfile(pwd, 'unqiueOrder.csv');
writecell(uniqueObjects, outputFile);