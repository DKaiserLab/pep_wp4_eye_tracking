function d = makeGDM(d, cfg)

if ~isfield(cfg, 'variables_of_interest')
cfg.variables_of_interest = {'ObjectFixCount',...
    'ObjectDwellsCate', 'ObjectDwellsCateEven', 'ObjectDwellsCateOdd',...
    'ObjectsCate_firstFix', 'ObjectsCate_firstFixEven', 'ObjectsCate_firstFixOdd',...
    'IndividualObjectDwells', 'IndividualObjects_firstFix',...
    'ObjectCatePrio', 'ObjectCatePrioOdd', 'ObjectCatePrioEven'};
end

for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    % get data
    subID = sprintf('sub-%0.3d', cfg.subNums(1));
    dataDir = fullfile(pwd, '..', 'derivatives', subID, 'gazePatterns', category);
    load(fullfile(dataDir, 'fixData.mat'))
    d.GDM.(category).isOdd = isOdd;

    for voi = cfg.variables_of_interest
        newMat = [];
        for iSub = 1:cfg.n

            % get data from subject
            subID = sprintf('sub-%0.3d', cfg.subNums(iSub));
            dataDir = fullfile(pwd, '..', 'derivatives', subID, 'gazePatterns', category);
            newData = load(fullfile(dataDir, [char(voi), '.mat']));

            % add to matrix
            if isempty(newMat)
                newMat = newData.(char(voi));
            else
                newMat = [newMat; newData.(char(voi))];
            end
        end

        % store in struct
        d.GDM.(category).(char(voi)) = newMat;

    end
end
end