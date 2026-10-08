function r_val = split_triplets_cor(all_images_rdm, cfg)

% Number of images
n_images = height(all_images_rdm);

% Check that images can be divided into triplets
if mod(n_images, 3) ~= 0
    error('Number of images must be divisible by 3.');
end

n_triplets = n_images / 3;

% Each row contains the indices belonging to one triplet:
%
% triplet 1: 1 2 3
% triplet 2: 4 5 6
% triplet 3: 7 8 9
% etc.

triplet_idx = reshape(1:n_images, 3, [])';

%% Randomly assign the three members of every triplet
% to RDM 1, RDM 2, and RDM 3.

rdm_idx = nan(n_triplets, 3);

for iTriplet = 1:n_triplets
    random_order = randperm(3);
    rdm_idx(iTriplet, :) = triplet_idx(iTriplet, random_order);
end

%% Construct the three subsampled RDM vectors
n_pairs = nchoosek(n_triplets, 2);
splitted_rdm = nan(n_pairs, 3);

for iRDM = 1:3
    this_idx = rdm_idx(:, iRDM);
    this_rdm = all_images_rdm(this_idx, this_idx);
    splitted_rdm(:, iRDM) = squareform(this_rdm);
end

%% Correlate the three RDMs
r_vals = corr(splitted_rdm, 'type', cfg.correlation_type, 'rows', 'pairwise');

% Three unique pairwise correlations:
% RDM1-RDM2
% RDM1-RDM3
% RDM2-RDM3

r_val = mean(r_vals(triu(true(3), 1)), 'omitnan');

end