function d = getSpliHalfReliability(d, cfg)

% loop through categories
cfg.dissimilarity = false; % use correlations not dissimilarity
for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    %% fixation count
    [ObserverFixOdd, ~] = corr(d.GDM.(category).ObjectMultiFixated(:,d.GDM.(category).isOdd(1,:))',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverFixEven, ~] = corr(d.GDM.(category).ObjectMultiFixated(:,~d.GDM.(category).isOdd(1,:))',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverFixOdd(logical(eye(size(ObserverFixOdd)))) = 0;
    [A] = squareform(ObserverFixOdd);
    % even
    ObserverFixEven(logical(eye(size(ObserverFixEven)))) = 0;
    [B] = squareform(ObserverFixEven);

    % print correlation
    disp(' ')
    disp('Fixation count')
    [R, p] = corr(A', B', 'Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.fixCount.r = R;

    % do permutation test
    res = doPermutations([A',B'], R, cfg);
    d.GDM.(category).splitHalfReliability.fixCount.p = res.p_value;
    d.GDM.(category).splitHalfReliability.fixCount.ci = [res.ci_lower, res.ci_upper];

    %% single object dwell time
    [ObserverMatOdd, ~] = corr(d.GDM.(category).ObjectDwellsMulti(:,d.GDM.(category).isOdd(1,:))',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEven, ~] = corr(d.GDM.(category).ObjectDwellsMulti(:,~d.GDM.(category).isOdd(1,:))',...
        'type', 'spearman', 'rows', 'complete');

    % runtime control
    disp(' ')
    disp(['Split-half reliablity for ', category, ' images'])

    % odd
    ObserverMatOdd(logical(eye(size(ObserverMatOdd)))) = 0;
    [C] = squareform(ObserverMatOdd);
    % even
    ObserverMatEven(logical(eye(size(ObserverMatEven)))) = 0;
    [D] = squareform(ObserverMatEven);

    % print and store correlation
    disp(' ')
    disp('Single object dwell time')
    [R, p] = corr(C', D','Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.singleObjects.r = R;

    % do permutation test
    res = doPermutations([C',D'], R, cfg);
    d.GDM.(category).splitHalfReliability.singleObjects.p = res.p_value;
    d.GDM.(category).splitHalfReliability.singleObjects.ci = [res.ci_lower, res.ci_upper];


    %% object category dwell time
    [ObserverMatOddCate, ~] = corr(d.GDM.(category).ObjectDwellsMultiCateOdd',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEvenCate, ~] = corr(d.GDM.(category).ObjectDwellsMultiCateEven',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOddCate(logical(eye(size(ObserverMatOddCate)))) = 0;
    [E] = squareform(ObserverMatOddCate);
    % even
    ObserverMatEvenCate(logical(eye(size(ObserverMatEvenCate)))) = 0;
    [F] = squareform(ObserverMatEvenCate);

    % print correlation
    disp(' ')
    disp('Category dwell time')
    [R, p] = corr(E', F', 'Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.objectCate.r = R;

    % do permutation test
    res = doPermutations([E',F'], R, cfg);
    d.GDM.(category).splitHalfReliability.objectCate.p = res.p_value;
    d.GDM.(category).splitHalfReliability.objectCate.ci = [res.ci_lower, res.ci_upper];

    %% first fix - single object dwell time

    % runtime control
    disp(' ')
    disp(['Split-half reliablity for ', category, ' images on first fixation'])

    [ObserverMatOdd, ~] = corr(d.GDM.(category).Objects_firstFix(:,d.GDM.(category).isOdd_firstFix(1,:))',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEven, ~] = corr(d.GDM.(category).Objects_firstFix(:,~d.GDM.(category).isOdd_firstFix(1,:))',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOdd(logical(eye(size(ObserverMatOdd)))) = 0;
    [G] = squareform(ObserverMatOdd);
    % even
    ObserverMatEven(logical(eye(size(ObserverMatEven)))) = 0;
    [H] = squareform(ObserverMatEven);

    % print and store correlation
    disp(' ')
    disp('Single object first fixation')
    [R, p] = corr(G', H', 'Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.singleObjectsFirstFix.r = R;

    % do permutation test
    res = doPermutations([G',H'], R, cfg);
    d.GDM.(category).splitHalfReliability.singleObjectsFirstFix.p = res.p_value;
    d.GDM.(category).splitHalfReliability.singleObjectsFirstFix.ci = [res.ci_lower, res.ci_upper];

    %% first fix - object category dwell time
    [ObserverMatOddCate, ~] = corr(d.GDM.(category).ObjectsCate_firstFixOdd',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEvenCate, ~] = corr(d.GDM.(category).ObjectsCate_firstFixEven',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOddCate(logical(eye(size(ObserverMatOddCate)))) = 0;
    [I] = squareform(ObserverMatOddCate);
    % even
    ObserverMatEvenCate(logical(eye(size(ObserverMatEvenCate)))) = 0;
    [J] = squareform(ObserverMatEvenCate);

    % print correlation
    disp(' ')
    disp('Category first fixation count')
    [R, p] = corr(I', J', 'Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.objectCateFirstFix.r = R;

    % do permutation test
    res = doPermutations([I',J'], R, cfg);
    d.GDM.(category).splitHalfReliability.objectCateFirstFix.p = res.p_value;
    d.GDM.(category).splitHalfReliability.objectCateFirstFix.ci = [res.ci_lower, res.ci_upper];

    %% object category fixation priority
    [ObserverMatOddCate, ~] = corr(d.GDM.(category).ObjectCatePrioOdd',...
        'type', 'spearman', 'rows', 'complete');
    [ObserverMatEvenCate, ~] = corr(d.GDM.(category).ObjectCatePrioEven',...
        'type', 'spearman', 'rows', 'complete');

    % odd
    ObserverMatOddCate(logical(eye(size(ObserverMatOddCate)))) = 0;
    [K] = squareform(ObserverMatOddCate);
    % even
    ObserverMatEvenCate(logical(eye(size(ObserverMatEvenCate)))) = 0;
    [L] = squareform(ObserverMatEvenCate);

    % print correlation
    disp(' ')
    disp('Category first fixation count')
    [R, p] = corr(K', L', 'Type', cfg.correlation_type);
    disp(['r: ' num2str(R) ', p = ' num2str(p)]);
    d.GDM.(category).splitHalfReliability.ObjectCatePrio.r = R;

    % do permutation test
    res = doPermutations([I',J'], R, cfg);
    d.GDM.(category).splitHalfReliability.ObjectCatePrio.p = res.p_value;
    d.GDM.(category).splitHalfReliability.ObjectCatePrio.ci = [res.ci_lower, res.ci_upper];
end
end

