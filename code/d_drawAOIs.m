% this demo code is part of Titta, a toolbox providing convenient access to
% eye tracking functionality using Tobii eye trackers
%
% Titta can be found at https://github.com/dcnieho/Titta. Check there for
% the latest version.
% When using Titta, please cite the following paper:
%
% Niehorster, D.C., Andersson, R. & Nystrom, M., (2020). Titta: A toolbox
% for creating Psychtoolbox and Psychopy experiments with Tobii eye
% trackers. Behavior Research Methods.
% doi: https://doi.org/10.3758/s13428-020-01358-8

clear variables; clear global; clear mex; close all; fclose('all'); clc

dbstop if error % for debugging: trigger a debug point when an error occurs


%% setup directories
myDir = pwd;
dirs.AOImasks = fullfile(myDir, '..', 'AOIs', 'AOImasks');
dirs.AOIs = fullfile(myDir, '..', 'AOIs');
if ~isfolder(dirs.AOIs)
    warning('AOI filder is missing');
end
dirs.funclib = fullfile(myDir, '..', '..', 'Titta', 'demo_analysis', 'function_library');
dirs.stims   = fullfile(myDir, '..', 'stimuli');

% add directories path
addpath(genpath(dirs.funclib));

% settings
trans = [.35 .9];
qAlsoIndivAOIs  = false;    % if true, also save image for each individual AOI

% make AOI masks output folder
if isdir(dirs.AOImasks) %#ok<ISDIR> 
    rmdir(dirs.AOImasks);
end

% see for which stimuli we have AOIs
disp('Loading AOIs...')
AOIs    = loadAllAOIFolders(dirs.AOIs,'png');

% make AOI masks output folder
if ~isdir(dirs.AOImasks) %#ok<ISDIR> 
    mkdir(dirs.AOImasks);
end

% defrine colors
aois_length = zeros(1,numel(AOIs));
for num_aois = 1:numel(AOIs)
    aois_length(num_aois) = numel(AOIs(num_aois).AOIs);
end
clr   = colormap(jet(max(aois_length)));

for f=1:length(AOIs)
    img     = imread(fullfile(dirs.stims, AOIs(f).name));
    allAOI  = img;
    fprintf(' %s\n',AOIs(f).name);
    
    if qAlsoIndivAOIs
        dirs.AOImasksf = fullfile(dirs.AOImasks,[AOIs(f).name '_AOIs']);
        if ~isdir(dirs.AOImasksf) %#ok<ISDIR> 
            mkdir(dirs.AOImasksf);
        end
    end
    
    % draw in individual AOIs
    for r=1:length(AOIs(f).AOIs)
        fprintf('  AOI: %s\n',AOIs(f).AOIs(r).name);
        
        allAOI  = drawAOIsOnImage(allAOI,AOIs(f).AOIs(r).bool,clr(r,:),trans);
        
        if qAlsoIndivAOIs
            AOIimage = drawAOIsOnImage(img ,AOIs(f).AOIs(r).bool,clr(r,:),trans);
            filenaam = [AOIs(f).AOIs(r).name '.jpg'];
            imwrite(AOIimage,fullfile(dirs.AOImasksf,filenaam),'jpg');
        end
    end
    
    imwrite(allAOI,fullfile(dirs.AOImasks,AOIs(f).name));
end
