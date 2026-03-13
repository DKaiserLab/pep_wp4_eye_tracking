function [RDM_plot, r_mat, p_mat, cfg] = partial_cor_RDM(cfg, RDMs)
%  PARTIAL_COR_RDM Brief summary of this function.
% 
% Detailed explanation of this function.
if ~isfield(cfg, 'RDM_to_partial_out'); cfg.RDM_to_partial_out = ...
        {'Typical Images vgg16_imagenet Late', 'Control Images vgg16_imagenet Late', 'Photos vgg16_imagenet Late'}; end
if ~isfield(cfg, 'partial_correlation_type'); cfg.partial_correlation_type = 'pearson';end
if ~isfield(cfg, 'correlation_type'); cfg.correlation_type = 'spearman';end
if ~isfield(cfg, 'plot_rdm'); cfg.plot_rdm = 1;end
% give RDM more comprehensive names
for rdm_name = 1:numel({RDMs.name})
    RDMs(rdm_name).name = cfg.labels{rdm_name};
    if ismember(cfg.labels{rdm_name}, cfg.RDM_to_partial_out)
        cfg.labels{rdm_name} = ['*partial* ',cfg.labels{rdm_name}];
    end
end
% loop through RDMs of interest
r_mat = zeros(numel({RDMs.name}),numel({RDMs.name}));
p_mat = r_mat;
for row = 1:numel({RDMs.name})
    RDMoi1 = RDMs(row);
    for col = 1:numel({RDMs.name})
        RDMoi2 = RDMs(col);
        % make diagonal equal 1
        if col == row
            r_mat(row, col) = 1;
            p_mat(row, col) = 1;
            % since RDMs are symetric we can avoid repetitions
        elseif col < row
            % vertorize RDMs
            h = height(RDMoi1.RDM);
            RDMoi1.RDM(eye(size(RDMoi1.RDM)) == 1) = 0;
            vec_RDM1 = squareform(RDMoi1.RDM)';
            RDMoi2.RDM(eye(size(RDMoi2.RDM)) == 1) = 0;
            vec_RDM2 = squareform(RDMoi2.RDM)';
            % check for missing values and remove from vector
            nans = isnan(vec_RDM1);
            if sum(nans) > 0
                vec_RDM1 = vec_RDM1(~nans);
                vec_RDM2 = vec_RDM2(~nans);
                if numel(vec_RDM1) ~= numel(vec_RDM2)
                    error('Size of matrices not equal due to missing values')
                end
            end
            % check if a partial correaltion is needed
            if xor(contains(RDMoi1.name, cfg.RDM_to_partial_out),contains(RDMoi2.name, cfg.RDM_to_partial_out))
                % define variables for partial correlation
                if contains(RDMoi1.name, cfg.RDM_to_partial_out)
                    other_name_indices = ~strcmp(RDMoi1.name, cfg.RDM_to_partial_out);
                elseif contains(RDMoi2.name, cfg.RDM_to_partial_out)
                    other_name_indices = ~strcmp(RDMoi2.name, cfg.RDM_to_partial_out);
                end
                % get other partials
                other_partials = cfg.RDM_to_partial_out(other_name_indices);
                other_RDMs_indices = find(ismember({RDMs.name}, other_partials));
                n_other_partials = numel(other_RDMs_indices);
                % loop through other partials
                other_partial_vectorized_RDMs = zeros(numel(vec_RDM1), n_other_partials);
                for i = 1:n_other_partials
                    current_partial_index = other_RDMs_indices(i);
                    % get RDM
                    current_RDM = RDMs(current_partial_index).RDM;
                    % vectorize RDM
                    current_RDM(eye(size(current_RDM)) == 1) = 0;
                    vec_current_RDM = squareform(current_RDM)';
                    % store in matrix
                    other_partial_vectorized_RDMs(:,i) = vec_current_RDM;
                end
                % get partial correlation
                [rho,pval] =  partialcorr(vec_RDM1, vec_RDM2, other_partial_vectorized_RDMs,...
                    'Rows', 'Pairwise', 'Tail','Right','Type', cfg.partial_correlation_type);
               
            else
                % correlate vertorized RDMs
                [rho,pval] = corr(vec_RDM1,vec_RDM2, 'type', cfg.correlation_type);
            end
            % store in output matrix (is symetric)
            r_mat(row, col) = rho;
            r_mat(col, row) = rho;
            p_mat(row, col) = pval;
            p_mat(col, row) = pval;
        end
    end % col
end % row
% plot RDM
if cfg.plot_rdm == 1
    RDM_plot = plot_RDM(r_mat, p_mat, cfg);
else
    RDM_plot = [];
end
end