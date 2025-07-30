function [RDM_plot, mat_out, pval] = cor_RDM(RDM_struct, cfg)
%  COR_RDM Brief summary of this function.
% 
% Detailed explanation of this function.
% evaluate input
if ~isfield(cfg, 'plot_rdm'); cfg.plot_rdm = false;end
if ~isfield(cfg, 'dissimilarity'); cfg.dissimilarity = false;end
% Initialize the struct array for vectorized RDMs
ratingVEC = struct('name', {}, 'vec', {});
nRDMs = length(RDM_struct);
for rdm = 1:nRDMs
    % Add name
    ratingVEC(rdm).name = RDM_struct(rdm).name;
    % vertorize RDM
    h = height(RDM_struct(rdm).RDM);
    ratingVEC(rdm).vec = RDM_struct(rdm).RDM(tril(true(h),-1));
    % generate vectorized RDM matrix (vector becomes column)
    mat_in(:, rdm) = ratingVEC(rdm).vec;
end
% make the RDM of RDM correlations
cfg.plotting = cfg.plot_rdm;
[RDM_plot, mat_out, pval] = make_RDM(mat_in, cfg);
end