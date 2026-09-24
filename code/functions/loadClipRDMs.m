function d = loadClipRDMs(d, cfg)

rdm_folder = fullfile(pwd, '..', 'dnn_features', 'clip', ['exp_', cfg.exp_name]);
faeture_modalities = {'image', 'joined'};  % there is also 'text' and 'joined';
drawing_modalities = {'raw', 'draw3D'};

for category = cfg.categories
    category = char(category);

    for faeture_modality = faeture_modalities
        faeture_modality = char(faeture_modality);

        for drawing_modality = drawing_modalities
            drawing_modality = char(drawing_modality);

            raw_tag = [];
            if strcmp(drawing_modality, 'raw')
                raw_tag = '_raw';
            end 

            rdm = readtable(fullfile(rdm_folder, ['rdm_clip_', drawing_modality, '_', faeture_modality, '_', category(1:3), '_typical.csv']));
            rdm = table2array(rdm);
            d.DNN.(['clip_', faeture_modality]).(['typical', raw_tag]).(category).subject_mean.name = ['clip_', drawing_modality, '_', faeture_modality];
            d.DNN.(['clip_', faeture_modality]).(['typical', raw_tag]).(category).subject_mean.color = [0,0,0];
            d.DNN.(['clip_', faeture_modality]).(['typical', raw_tag]).(category).subject_mean.RDM = rdm(2:end, 2:end);

            rdm = readtable(fullfile(rdm_folder, ['rdm_clip_', drawing_modality, '_', faeture_modality, '_', category(1:3), '_copy.csv']));
            rdm = table2array(rdm);
            d.DNN.(['clip_', faeture_modality]).(['control', raw_tag]).(category).subject_mean.name = ['clip_', drawing_modality, '_', faeture_modality];
            d.DNN.(['clip_', faeture_modality]).(['control', raw_tag]).(category).subject_mean.color = [0,0,0];
            d.DNN.(['clip_', faeture_modality]).(['control', raw_tag]).(category).subject_mean.RDM = rdm(2:end, 2:end);
        end
    end
end
end