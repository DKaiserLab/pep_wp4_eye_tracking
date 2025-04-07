function d = getSpliHalfReliability(d, cfg)

% evaluate input
if ~isfield(cfg, 'variables_of_interest')
    cfg.variables_of_interest = {'ObjectFixCount',...
        'ObjectDwellsCate', 'ObjectsCate_firstFix',...
        'IndividualObjectDwells', 'IndividualObjects_firstFix',...
        'ObjectCatePrio'};
end
if ~isfield(cfg, 'labels'); cfg.labels = {'odd', 'even'}; end
if ~isfield(cfg, 'regressOutMean'); cfg.regressOutMean = true; end

if cfg.regressOutMean
    GDM_field = 'GDM_demeaned';
else
    GDM_field = 'GDM';
end 
cfg.dissimilarity = false; % use correlations not dissimilarity


% loop through categories
for iCate = 1:length(cfg.categories)
    category = cfg.categories{iCate};

    %% fixation count
    if ismember('ObjectFixCount' , cfg.variables_of_interest)
        numImgs = size(d.(GDM_field).(category).ObjectFixCount, 2);
        [ObserverFixOdd, ~] = corr(d.(GDM_field).(category).ObjectFixCount(:,1:2:numImgs)',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverFixEven, ~] = corr(d.(GDM_field).(category).ObjectFixCount(:,2:2:numImgs)',...
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
        [R, p] = corr(A', B', 'Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.ObjectFixCount.r = R;

        % do permutation test
        res = doPermutations([A',B'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.ObjectFixCount.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.ObjectFixCount.ci = [res.ci_lower, res.ci_upper];
    end

    %% single object dwell time
    if ismember('IndividualObjectDwells' , cfg.variables_of_interest)
        [ObserverMatOdd, ~] = corr(d.(GDM_field).(category).IndividualObjectDwells(:,d.(GDM_field).(category).isOdd(1,:))',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverMatEven, ~] = corr(d.(GDM_field).(category).IndividualObjectDwells(:,~d.(GDM_field).(category).isOdd(1,:))',...
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
        [R, p] = corr(C', D','Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.IndividualObjectDwells.r = R;

        % do permutation test
        res = doPermutations([C',D'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.IndividualObjectDwells.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.IndividualObjectDwells.ci = [res.ci_lower, res.ci_upper];
    end

    %% object category dwell time
    if ismember('ObjectDwellsCate' , cfg.variables_of_interest)
        [ObserverMatOddCate, ~] = corr(d.(GDM_field).(category).ObjectDwellsCateOdd',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverMatEvenCate, ~] = corr(d.(GDM_field).(category).ObjectDwellsCateEven',...
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
        [R, p] = corr(E', F', 'Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.ObjectDwellsCate.r = R;

        % do permutation test
        res = doPermutations([E',F'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.ObjectDwellsCate.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.ObjectDwellsCate.ci = [res.ci_lower, res.ci_upper];
    end

    %% first fix - single object dwell time
    if ismember('IndividualObjects_firstFix' , cfg.variables_of_interest)

        % runtime control
        disp(' ')
        disp(['Split-half reliablity for ', category, ' images on first fixation'])

        [ObserverMatOdd, ~] = corr(d.(GDM_field).(category).IndividualObjects_firstFix(:,d.(GDM_field).(category).isOdd(1,:))',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverMatEven, ~] = corr(d.(GDM_field).(category).IndividualObjects_firstFix(:,~d.(GDM_field).(category).isOdd(1,:))',...
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
        [R, p] = corr(G', H', 'Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.IndividualObjects_firstFix.r = R;

        % do permutation test
        res = doPermutations([G',H'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.IndividualObjects_firstFix.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.IndividualObjects_firstFix.ci = [res.ci_lower, res.ci_upper];
    end

    %% first fix - object category dwell time
    if ismember('ObjectsCate_firstFix' , cfg.variables_of_interest)
        [ObserverMatOddCate, ~] = corr(d.(GDM_field).(category).ObjectsCate_firstFixOdd',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverMatEvenCate, ~] = corr(d.(GDM_field).(category).ObjectsCate_firstFixEven',...
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
        [R, p] = corr(I', J', 'Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.ObjectsCate_firstFix.r = R;

        % do permutation test
        res = doPermutations([I',J'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.ObjectsCate_firstFix.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.ObjectsCate_firstFix.ci = [res.ci_lower, res.ci_upper];
    end

    %% object category fixation priority
    if ismember('ObjectCatePrio' , cfg.variables_of_interest)
        [ObserverMatOddCate, ~] = corr(d.(GDM_field).(category).ObjectCatePrioOdd',...
            'type', 'spearman', 'rows', 'complete');
        [ObserverMatEvenCate, ~] = corr(d.(GDM_field).(category).ObjectCatePrioEven',...
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
        [R, p] = corr(K', L', 'Type', cfg.correlation_type, 'rows', 'pairwise');
        disp(['r: ' num2str(R) ', p = ' num2str(p)]);
        d.(GDM_field).(category).splitHalfReliability.ObjectCatePrio.r = R;

        % do permutation test
        res = doPermutations([I',J'], R, cfg);
        d.(GDM_field).(category).splitHalfReliability.ObjectCatePrio.p = res.p_value;
        d.(GDM_field).(category).splitHalfReliability.ObjectCatePrio.ci = [res.ci_lower, res.ci_upper];
    end
end
end

