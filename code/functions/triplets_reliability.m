function d = triplets_reliability(cfg, d)


% evaluate input
if ~isfield(cfg, 'dnn'); cfg.dnn = 'vgg16_imagenet';end
if ~isfield(cfg, 'categories');  cfg.categories = {'kitchen', 'bathroom'};end
if ~isfield(cfg, 'analysis_names');  cfg.analysis_names = {'typical', 'control'};end
if ~isfield(cfg, 'correlation_type'); cfg.correlation_type = 'Spearman'; end
if ~isfield(cfg, 'n_permutations'); cfg.n_permutations = 10000; end

cfg.dissimilarity = false; % use correlations not dissimilarity


%lopp through analyses
for analysis_name = cfg.analysis_names
    analysis_name = char(analysis_name);

    % loop through categories
    for iCate = 1:length(cfg.categories)
        category = cfg.categories{iCate};

        % split RDM into triplets
        all_images_rdm = d.DNN.(cfg.dnn).(analysis_name).(category).all_images.RDM;
        d.DNN.(cfg.dnn).(analysis_name).(category).triplet_corr = split_triplets_cor(all_images_rdm, cfg);

        % permutation test
        rng(1)
        perm_mean_rs = nan(1, cfg.n_permutations);
        for perm = 1:cfg.n_permutations
            rand_seq = randperm(height(all_images_rdm));
            all_images_rdm_perm = all_images_rdm(rand_seq, rand_seq);

            perm_mean_rs(perm) = split_triplets_cor(all_images_rdm_perm, cfg);
        end
        d.DNN.(cfg.dnn).(analysis_name).(category).triplet_corr_perms = perm_mean_rs;

    end

    % take category mean
    observed_r_mean = (d.DNN.(cfg.dnn).(analysis_name).(cfg.categories{1}).triplet_corr + ...
        d.DNN.(cfg.dnn).(analysis_name).(cfg.categories{2}).triplet_corr)/2;
    perm_r_mean = (d.DNN.(cfg.dnn).(analysis_name).(cfg.categories{1}).triplet_corr_perms +...
        d.DNN.(cfg.dnn).(analysis_name).(cfg.categories{2}).triplet_corr_perms)/2;

    % get p value 
    p = sum(perm_r_mean >= observed_r_mean)/cfg.n_permutations;

    disp(['Triplets reliabilty test for ', analysis_name, ':'])
    disp(['     r = ', num2str(observed_r_mean)])
    disp(['     p = ', num2str(p)])

    % store in results struct
    d.DNN.(cfg.dnn).(analysis_name).combined.triplet_corr = observed_r_mean;
    d.DNN.(cfg.dnn).(analysis_name).combined.triplet_corr_perms_mean = perm_r_mean;
    d.DNN.(cfg.dnn).(analysis_name).combined.p_value = p;
end
end

