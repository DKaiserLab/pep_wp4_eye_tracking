function [RDMs,labels] = evaluate_triplet_predictor_RDMs(d, RDMs, labels, cfg, category)

% get lenght of RDMs and lables 
n_rdms = length(RDMs);
labels_rdms = length(labels);
if n_rdms == labels_rdms
    disp(' Start evaluating predictor RDMs')
else
    warning('RDMs and labels have not the same length')
end

% get dnn models that are not available in matlab
matlab_dnns = cfg.dnns(~ismember(cfg.dnns, {'clip', 'dino'}));

% human rated simiarlairties
for rdm_num = 1:numel(cfg.predictor_RDMs)

    % decide between raw and draw3D images
    raw_tag = [];
    if contains(cfg.predictor_RDMs{rdm_num}, 'raw')
        raw_tag = '_raw';
    end 

    % DNN similarities for control drawings based on generated images

    for dnn = matlab_dnns
        dnn = char(dnn);

        % early
        if contains(cfg.predictor_RDMs{rdm_num}, 'control_early')
            rdm_index = 1;
            RDMs(end + 1) = d.DNN.(dnn).(['control', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Control Images ', dnn, ' Early'];

        % medium
        elseif contains(cfg.predictor_RDMs{rdm_num}, 'control_medium')
            rdm_index = ceil(length(d.DNN.(dnn).(['control', raw_tag]).(category).all_images)/2);
            RDMs(end + 1) = d.DNN.(dnn).(['control', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Control Images ', dnn, ' Medium'];

        % late
        elseif contains(cfg.predictor_RDMs{rdm_num}, 'control_late')
            rdm_index = length(d.DNN.(dnn).(['control', raw_tag]).(category).all_images);
            RDMs(end + 1) = d.DNN.(dnn).(['control', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Control Images ', dnn, ' Late'];
        end
    end


    %% DNN similarities for own drawings based on generated images

    for dnn = matlab_dnns
        dnn = char(dnn);

        % early
        if contains(cfg.predictor_RDMs{rdm_num}, 'typical_early')
            rdm_index = 1;
            RDMs(end + 1) = d.DNN.(dnn).(['typical', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Typical Images ', dnn, ' Early'];

        % medium
        elseif contains(cfg.predictor_RDMs{rdm_num}, 'typical_medium')
            rdm_index = ceil(length(d.DNN.(dnn).(['typical', raw_tag]).(category).all_images)/2);
            RDMs(end + 1) = d.DNN.(dnn).(['typical', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Typical Images ', dnn, ' Medium'];

        % late
        elseif contains(cfg.predictor_RDMs{rdm_num}, 'typical_late')
            rdm_index = length(d.DNN.(dnn).(['typical', raw_tag]).(category).all_images);
            RDMs(end + 1) = d.DNN.(dnn).(['typical', raw_tag]).(category).all_images(rdm_index);
            labels{end + 1} = ['Typical Images ', dnn, ' Late'];
        end
    end
end


% check is RDMs and Lebsl have same length
if length(RDMs) == length(labels)
    disp('Predictor RDMs evaluated')
else
    warning('RDMs and labels have not the same length')
end
end