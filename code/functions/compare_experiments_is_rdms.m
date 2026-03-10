function res = compare_experiments_is_rdms(iscMat, nPerm)

if nargin < 2
    nPerm = 10000;
end

nSub = size(iscMat,1);
half = nSub/2;

if mod(nSub,2) ~= 0
    error('Number of subjects must be even.');
end

%% Original group labels
group = [ones(half,1); 2*ones(half,1)];

%% Extract upper triangle
mask = triu(true(nSub),1);
[i,j] = find(mask);

pairs = iscMat(mask);

%% Identify within / between pairs
withinMask = group(i) == group(j);
betweenMask = group(i) ~= group(j);

withinMean  = median(pairs(withinMask));
betweenMean = median(pairs(betweenMask));

obsStat = withinMean - betweenMean;

%% ---- Permutation test ----
permStats = zeros(nPerm,1);

for p = 1:nPerm
    
    % shuffle group labels
    permGroup = group(randperm(nSub));
    
    withinMaskPerm  = permGroup(i) == permGroup(j);
    betweenMaskPerm = permGroup(i) ~= permGroup(j);
    
    permStats(p) = median(pairs(withinMaskPerm)) - median(pairs(betweenMaskPerm));
    
end

%% p-value (one-sided)
pval = sum(permStats >= obsStat) / nPerm;

%% Output
res.obsStat = obsStat;
res.withinMean = withinMean;
res.betweenMean = betweenMean;
res.p = pval;
res.permStats = permStats;

fprintf('Within ISC: %.4f\n',withinMean);
fprintf('Between ISC: %.4f\n',betweenMean);
fprintf('Difference: %.4f\n',obsStat);
fprintf('Permutation p-value: %.5f\n',pval);

end