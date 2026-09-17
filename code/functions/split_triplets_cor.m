function r_val = split_triplets_cor(all_images_rdm, cfg)
        
        % split triplets
        trp_idx = mod(1:height(all_images_rdm), 3) + 1;
        splitted_rdm = nan(nchoosek(cfg.n, 2), 3);
        splitted_rdm(:, 1) = squareform(all_images_rdm(trp_idx==1, trp_idx==1));
        splitted_rdm(:, 2) = squareform(all_images_rdm(trp_idx==2, trp_idx==2));
        splitted_rdm(:, 3) = squareform(all_images_rdm(trp_idx==3, trp_idx==3));

        % correlate triplets
        [r_vals, ~] = corr(splitted_rdm, 'type', 'spearman', 'rows', 'pairwise');
        r_vals(eye(size(r_vals)) == 1) = 0;
        try
            r_val = mean(squareform(r_vals));
        catch
            disp(r_vals)
            r_val = nan;
        end 

end 