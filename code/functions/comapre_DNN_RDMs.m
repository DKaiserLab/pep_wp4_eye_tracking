function d = comapre_DNN_RDMs(d, cfg)


drawing_modalities = {'raw', 'draw3D'};
dnns = fieldnames(d.DNN)';
%dnns = {'vgg16_imagenet', 'clip_image', 'vggnet16_places365'};

for category = cfg.categories
    category = char(category);

    all_rdms_typ = [];
    res_linear = [];
    res_rank = [];
    all_names = {};
    counter = 0;


    for dnn = dnns
        dnn = char(dnn);

        for drawing_modality = drawing_modalities
            drawing_modality = char(drawing_modality);

            counter = counter + 1;

            raw_tag = [];
            if strcmp(drawing_modality, 'raw')
                raw_tag = '_raw';
            end

            new_rdm_typ = d.DNN.(dnn).(['typical', raw_tag]).(category).subject_mean.RDM;
            new_rdm_typ(eye(size(new_rdm_typ)) == 1) = 0;
            all_rdms_typ(:, counter) = squareform(new_rdm_typ)';

            new_rdm_ctr = d.DNN.(dnn).(['control', raw_tag]).(category).subject_mean.RDM;
            new_rdm_ctr(eye(size(new_rdm_ctr)) == 1) = 0;

            [res_linear(:, counter), res_rank(:, counter)] = ...
                regress_out(squareform(new_rdm_typ)', squareform(new_rdm_ctr)');

            all_names{counter} = [dnn, '_', drawing_modality];
        end
    end

    % correlate RDMs
    [r, ~] = corr(all_rdms_typ, 'type', 'spearman', 'rows', 'pairwise');
    d.DNN_comparison.(category).r_typ = r;
    d.DNN_comparison.(category).dnn_names = all_names;

    [r, ~] = corr(res_linear, 'type', 'spearman', 'rows', 'pairwise');
    d.DNN_comparison.(category).r_partial_linear = r;
    d.DNN_comparison.(category).dnn_names = all_names;

    [r, ~] = corr(res_rank, 'type', 'spearman', 'rows', 'pairwise');
    d.DNN_comparison.(category).r_partial_rank = r;
    d.DNN_comparison.(category).dnn_names = all_names;

    %     figure;
    %     deoras_heatmap(r, all_names, all_names, [], 'TickAngle', 45)
    %     colorbar
    %     title(category)

end

r_avg = (d.DNN_comparison.bathroom.r_typ + d.DNN_comparison.bathroom.r_typ)/2;

figure;
deoras_heatmap(r_avg, all_names, all_names, 1, 'TickAngle', 45, 'MinColorValue', -1, 'MaxColorValue', 1)
colorbar
title('Category average typical')

r_avg = (d.DNN_comparison.bathroom.r_partial_linear + d.DNN_comparison.bathroom.r_partial_linear)/2;

figure;
deoras_heatmap(r_avg, all_names, all_names, 1, 'TickAngle', 45, 'MinColorValue', -1, 'MaxColorValue', 1)
colorbar
title('Category average partial linear')

r_avg = (d.DNN_comparison.bathroom.r_partial_rank + d.DNN_comparison.bathroom.r_partial_rank)/2;

figure;
deoras_heatmap(r_avg, all_names, all_names, 1, 'TickAngle', 45, 'MinColorValue', -1, 'MaxColorValue', 1)
colorbar
title('Category average partial rank')


end

function [y_res_linear, y_res_rank] = regress_out(y, x)

% Remove observations with NaNs
valid = ~isnan(x) & ~isnan(y);

xv = x(valid);
yv = y(valid);


%% 1. Linear regression
% y = b0 + b1*x + error

X = [ones(size(xv)) xv];

b = X \ yv;

y_res_linear = nan(size(y));
y_res_linear(valid) = yv - X*b;


%% 2. Rank regression
% (i.e., Spearman-type regression)

x_rank = tiedrank(xv);
y_rank = tiedrank(yv);

X_rank = [ones(size(x_rank)) x_rank];

b_rank = X_rank \ y_rank;

y_res_rank = nan(size(y));
y_res_rank(valid) = y_rank - X_rank*b_rank;

end