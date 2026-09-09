function Strain_DegradationAnalysis

% Degradation analysis of C-ring samples. The degradation is separated
% regarding tensile strain and compressive strain region to analyze the
% degradation behavior that is induced on both sides. For the calculation,
% an initial undegraded scan is required next to the degraded scan to 
% calculate the exact degradation depth.
% The calculation includes:
%   - overall degradation rate (DR) and mean degradation depth (MDD)
%   - DR, MDD, PF_2D, PF_3D of tensile and compressive side

close all

% which sample should be analyzed?
sample = ;
voxel_size = ; % in µm

filepath = ''; % where are all the samples (e.g., reco folder)
folder_name = ''; % what is the folder name of the segmented images?

% Sample information
sample_numbers      = [];
sample_deformations = [];
sample_degradations = [];

%%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%

%% Pre-definitions
% from sample: determine deformation and degradation
deg_time    = sample_degradations(sample_numbers == sample);
deformation = sample_deformations(sample_numbers == sample);

% For some calculations, he top and bottom regions are neglected. This is
% due to the samples not being perfectly aligned and thereby leading to
% wrong calculations.
omit_slices = 100;

%% Loading images
fprintf('Lets start %d... :)\n', sample)

% Reading image files: it's faster if the files are loaded as mat-files 
% (has to be saved as a mat-file in the first read-in)
dir_variables      = dir([filepath '*' num2str(sample) '*']);
location_variables = dir_variables.folder;

% Have the samples already been read-in and saved?
if isfile([location_variables sprintf('%d_specimen_initial.mat',sample)])==1
    fprintf('Image stacks loading from mat-file \n')

    loaded_degradation   = load([location_variables sprintf('%d_specimen_degradation.mat',sample)]);
    loaded_initial       = load([location_variables sprintf('%d_specimen_initial.mat',sample)]);
    specimen_degradation = loaded_degradation.specimen_degradation;
    specimen_initial     = loaded_initial.specimen_initial;
else
    fprintf('Image stack loading from tif-files \n')
    
    % find folder path of segmented images of degraded sample
    dir_images           = dir([filepath '*' num2str(sample) '*/*' folder_name]);
    filepath_degradation = dir_images.folder;
    addpath(filepath_degradation);

    fprintf('Loading degraded images...\n')
    specimen_degradation = ReadIn_images(filepath_degradation);
    
    % Export images as .mat-file to save computation time
    save(fullfile(location_variables,sprintf('%d_specimen_degradation.mat',sample)),'specimen_degradation','-v7.3');
    
    % find folder path of segmented images of initial sample
    dir_initial      = dir([filepath '*' num2str(sample) '*/initial/*']);
    filepath_initial = dir_initial.folder;
    addpath(filepath_initial);

    fprintf('Loading initial images...\n')
    specimen_initial = ReadIn_images(filepath_initial);

    % Export images as .mat-file to save computation time
    save(fullfile(location_variables,sprintf('%d_specimen_initial.mat',sample)),'specimen_initial','-v7.3');
end

% Define px value for later calculations
degradation    = uint8(specimen_degradation>1);
res_material   = uint8(specimen_degradation==1);
initial_sample = uint8(specimen_initial>0);

%% Surface calculation
% The surface is determined for the following calculations. As the surface
% detection is very time consuming, the surface is exported as a .mat-file.

% Check if the surface has been determined before
if isfile([location_variables sprintf('%d_surface_plot_degraded.mat',sample)])==1
    fprintf('Loading area and surface results...\n')

    % Load the already determined surface results
    loaded_plot_degraded  = load([location_variables sprintf('%d_surface_plot_degraded.mat',sample)]);
    loaded_plot_initial   = load([location_variables sprintf('%d_surface_plot_initial.mat',sample)]);
    loaded_area_initial   = load([location_variables sprintf('%d_area_initial.mat',sample)]);
    surface_plot_degraded = loaded_plot_degraded.surface_plot_degraded;
    surface_plot_initial  = loaded_plot_initial.surface_plot_initial;
    area_initial          = loaded_area_initial.area_initial;
else
    % Surface has not been determined before: it is determined for the
    % initial and degraded sample
    [~, surface_plot_degraded]          = contact_area(res_material,1,0);
    [area_initial,surface_plot_initial] = contact_area(initial_sample,1,0);

    area_initial = area_initial*(voxel_size*10^(-3))^2; %mm^2

    % Export the surface results
    save(fullfile(location_variables,sprintf('%d_surface_plot_degraded.mat',sample)),'surface_plot_degraded','-v7.3');
    save(fullfile(location_variables,sprintf('%d_surface_plot_initial.mat',sample)),'surface_plot_initial','-v7.3');
    save(fullfile(location_variables,sprintf('%d_area_initial.mat', sample)), 'area_initial');
end

%% Overall degradation results
% In the first step, the overall degradation parameter are calculated. It
% is averaged over the whole sample so also tensile and compressive side.

% 1. Degradation rate (DR) in mm/y
degradation_rate = (nnz(initial_sample)-nnz(res_material))*(voxel_size*10^(-3))^3/(area_initial*deg_time/52); %mm/y

% In case the initial nnz is smaller than degradation, use mean value
if degradation_rate<0
    nnz_initial      = 750790661; %nnz mean of 5 samples
    degradation_rate = (nnz_initial-nnz(res_material))*(voxel_size*10^(-3))^3/(area_initial*deg_time/52); %mm/y
    fprintf('Attention please: nnz initial smaller than degraded!\n')
end

% 2. Mean degradation depth (MDD) in µm
degradation_depth = degradation_rate*deg_time/52*10^3; %µm

fprintf('The overall degradation rate is %f mm/y. \n',degradation_rate)
fprintf('The overall degradation depth is %f µm. \n', degradation_depth)

%% Define tensile and compressive side

% The segmented images are separated to inside (compression) and outside
% (tension).

% Cropping of the images to the ROI (if it is not already segmented such)
if size(res_material,3) > 1800
    surface_plot_degraded = surface_plot_degraded(:,round(size(surface_plot_initial,2)/2):end,:);
    surface_plot_initial  = surface_plot_initial(:,round(size(surface_plot_degraded,2)/2):end,:);
end

fprintf('Calculate inside and outside...\n')

% Define inside and outside of the stacks
inside_distances  = zeros(size(surface_plot_initial,1),1,size(surface_plot_initial,3));
outside_distances = zeros(size(surface_plot_degraded,1),1,size(surface_plot_initial,3));


% Find first(inside) and last(outside) entry in the surface plots
% The first and last 15 slices are omitted since there the sample is
% appearing and it's not accurate to include those in the following
% calculations
for index_slice = omit_slices:size(inside_distances,3)-omit_slices
    for index_row = 1:size(inside_distances,1)
        [~,col_ins_in]  = find(surface_plot_initial(index_row,:,index_slice),1,'first');
        [~,col_out_in]  = find(surface_plot_initial(index_row,:,index_slice),1,'last');
        [~,col_ins_res] = find(surface_plot_degraded(index_row,:,index_slice),1,'first');
        [~,col_out_res] = find(surface_plot_degraded(index_row,:,index_slice),1,'last');

        % Calculate distance between the two positions(=distance in px)
        % inside and outside and convert it to distance in µm
        if col_ins_res>0 & col_ins_in>0 % otherwise the calculation leads to a 1x0 element which can't be assigned to the array
            inside_distances(index_row,1,index_slice)  = (col_ins_res-col_ins_in)*voxel_size;
            outside_distances(index_row,1,index_slice) = (col_out_in-col_out_res)*voxel_size;
        end
    end
end

% delete negative inside and outside values (due to wrong registration)
inside_distances  = inside_distances.*(inside_distances>0);
outside_distances = outside_distances.*(outside_distances>0);

%% Tension and compression calculations 

% Calculate mean and max of each slice for pitting factor
mean_distance_inside  = mean(inside_distances,[1 2]);
mean_distance_outside = mean(outside_distances,[1 2]);
max_distance_inside   = max(inside_distances,[],[1 2]);
max_distance_outside  = max(outside_distances,[],[1 2]);

% Rearrange values 
mean_distance_inside  = permute(mean_distance_inside,[3 1 2]);
mean_distance_outside = permute(mean_distance_outside,[3 1 2]);
max_distance_inside   = permute(max_distance_inside, [3 1 2]);
max_distance_outside  = permute(max_distance_outside, [3 1 2]);

% Calculate pitting factor (slice wise)
pitting_factor_inside  = max_distance_inside./mean_distance_inside;
pitting_factor_outside = max_distance_outside./mean_distance_outside;

% delete Inf values (due to the deleted negative mean values)
pitting_factor_inside  = pitting_factor_inside.*(~isinf(pitting_factor_inside));
pitting_factor_outside = pitting_factor_outside.*(~isinf(pitting_factor_outside));

% Calculate overall mean and std and max
mean_overall_inside  = mean(inside_distances,'all');
mean_overall_outside = mean(outside_distances,'all');
std_overall_inside   = std(inside_distances,0,'all');
std_overall_outside  = std(outside_distances,0,'all');
max_max_inside       = max(inside_distances,[],'all');
max_max_outside      = max(outside_distances,[],'all');

% Pitting factors overall
averaged_pitting_inside   = mean(pitting_factor_inside,'all','omitnan');
averaged_pitting_outside  = mean(pitting_factor_outside,'all','omitnan');
std_pitting_inside        = std(pitting_factor_inside,0,'all','omitnan');
std_pitting_outside       = std(pitting_factor_outside,0,'all','omitnan');
pitting_factor_3d_inside  = max_max_inside/mean_overall_inside;
pitting_factor_3d_outside = max_max_outside/mean_overall_outside;

plusminus=char(177);
fprintf('The mean degradation depth on the outside is %.3f %s %.3f µm.\n',mean_overall_outside, plusminus, std_overall_outside)
fprintf('The mean degradation depth on the inside is %.3f %s %.3f µm.\n',mean_overall_inside, plusminus, std_overall_inside)
fprintf('The 2D pitting factor on the outside is %.3f %s %.3f.\n', averaged_pitting_outside,plusminus,std_pitting_outside)
fprintf('The 2D pitting factor on the inside is %.3f %s %.3f.\n', averaged_pitting_inside,plusminus,std_pitting_inside)
fprintf('The 3D pitting factor on the outside is %.3f.\n', pitting_factor_3d_outside)
fprintf('The 3D pitting factor on the inside is %.3f.\n', pitting_factor_3d_inside)

%% Optional calculation
% Calculate volume of the two degradation layers

cc_degradation = bwconncomp(degradation(:,:,omit_slices:end-omit_slices)); % determine the connected components (cc) in degradation layer
cc_area        = regionprops(cc_degradation,'Area'); % calculate area of the cc
[cc_largest_areas, cc_index] = maxk([cc_area.Area],2); % omit all except the largest 2: first is inside, second is outside

inside_volume   = cc_largest_areas(cc_index==min(cc_index))*(voxel_size*10^-3)^3; % calculate actual volume of inside degradation layer in µm³
outside_volume  = cc_largest_areas(cc_index==max(cc_index))*(voxel_size*10^-3)^3; % calculate actual volume of outside degradation layer in µm³

fprintf('The volume of the outside degradation layer is %.2f mm³.\n',outside_volume)
fprintf('The volume of the inside degradation layer is %.2f mm³.\n',inside_volume)
end