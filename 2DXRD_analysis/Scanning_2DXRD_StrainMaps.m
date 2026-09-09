function Scanning_2DXRD_StrainMaps
% The strain maps of the (10-10), (0002), and (10-11) planes of Mg are
% calculated based on the elongation of the diffraction rings obtained by
% scanning 2D XRD. The ellipse fitting is based on the following equations:
%   strain = (l_major-l_0)/l_0 with
%   l_0    = sqrt(A/pi) with 
%   A      = pi * l_semimajor * l_semiminor

% To reduce computation time, the diffraction patterns and the fit results
% are saved as .mat files.

% The following information have to be given in the beginning:
%   filepath:   filepath of the diffraction patterns
%   writepath:  path, where the strain maps are saved and intermediate
%               calculation step
%   image_rows: scan height (in px) 
%   image_cols: scan width (in px)

close all

exporting = 0; % should the images be exported? 1=yes, 0=no

% Scan information
sample = ; % which sample should be analyzed?
filepath   = ''; % folder path, where all diffraction pattern images are
writepath  = ''; % folder, where all results are saved
image_rows = ; % scan height in px
image_cols = ; % scan width in px
addpath(filepath);
addpath(writepath);

%%%%%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load diffraction images
% 1. Find the exact folder that contains the diffraction images of the
% defined sample
directory_path = dir([filepath '*' num2str(sample) '*']); % find the exact folder name of the wanted sample
imagepath      = directory_path.folder;
addpath(imagepath)

% 2. Load images or fit data
% 2a. were the images already fit by an ellipse? Then only the fit results
% are loaded instead of all the images
if isfile([writepath sprintf('Ellipse_results_%d.mat', sample)])==1
    fprintf('Ellipse was already fit: loading results...\n')
    loaded_ellipse_results = load([writepath sprintf('Ellipse_results_%d.mat', sample)]);
    ellipse_results        = loaded_ellipse_results.ellipse_results;

% 2b. haven't the images been fit already by an ellipse? Then have the 
% images already been saved as a .mat file? If yes, load these.
elseif isfile([writepath sprintf('diffraction_images_%d.mat',sample)])==1
    fprintf('Loading deformed images from mat file...\n')
    loaded_images      = load([writepath sprintf('diffraction_images_%d.mat', sample)]);
    diffraction_images = loaded_images.diffraction_images;

% 2c. if neither the images have been saved as a .mat file nor the ellipse
% has been fit, the original images are read from the previously determined
% folder:
else
    fprintf('Opening deformed images from raw folder...\n')
    diffraction_images = ReadIn_images(imagepath);
    save(fullfile(writepath, sprintf('diffraction_images_%d.mat', sample)), 'diffraction_images', '-v7.3');
    fprintf('Saving deformed images as mat file...\n')
end

%% Ellipse fitting
% The ellipse fitting is only required once. Afterwards, the results are
% saved in the writepath folder to save computation time. Obtained are the
% semimajor and semiminor axis lengths, along with the rotation angle.
% If the ellipse fitting does not yield results, vary the threshold.

if ~exist('ellipse_results',"var")
    fprintf('No previous thresholding and fitting found \n')

    %%%%% Diffraction ring masking %%%%%
    % Load diffraction ring masks that were manually created before.
    mask_first_in   = imread([writepath 'Mask_inside_first.tif']); % deletes primary beam
    mask_first_out  = imread([writepath 'Mask_outside_first.tif']); % would show first ring + primary beam
    mask_second_out = imread([writepath 'Mask_outside_second.tif']); % would show first, second ring + primary beam
    mask_third_out  = imread([writepath 'Mask_outside_third.tif']); % would show first, second ring, third + primary beam

    % Create masks for the first three diffraction rings of Mg (norming to
    % 1)
    mask_first_ring  = (mask_first_out - mask_first_in)./255;
    mask_second_ring = (mask_second_out - mask_first_out)./255;
    mask_third_ring  = (mask_third_out - mask_second_out)./255;

    % Multiply masks with diffraction pattern
    masked_first  = double(diffraction_images).*double(mask_first_ring);
    masked_second = double(diffraction_images).*double(mask_second_ring);
    masked_third  = double(diffraction_images).*double(mask_third_ring);

    %%%%% Fit ellipses to deformed C-Ring %%%%%%

    % Threshold images
    fprintf('Threshold images...\n')
    threshold_value  = 0.0004; 
    eta              = max(diffraction_images,[],'all');
    threshold_first  = double(masked_first>(eta*threshold_value));
    threshold_second = double(masked_second>(eta*threshold_value));
    threshold_third  = double(masked_third>(eta*threshold_value));

    % Fit ellipse and calculate ellipse parameter
    [ellipse_results, image_first] = FitEllipse_DiffractionPattern(threshold_first, threshold_second, threshold_third, image_rows, image_cols);
    save(fullfile(writepath, sprintf('Ellipse_results_%d.mat', sample)), 'ellipse_results', '-v7.3');
    save(fullfile(writepath, sprintf('Image_first_%d.mat', sample)), 'image_first', '-v7.3'); % required for registering of line plots 
end

%% Strain calculation
% The strain is calculated according to e=delta_l/l_0, where l is the
% semimajor axis length and l_0 the undeformed semimajor axis length. The
% calculation is as follows:
%   1. Calculate the area of the ellipse
%   2. Assume that the undeformed diffraction ring has the same area and
%      calculate its diameter l_0
%   3. Calculate strain with individual l and determined l_0

% pre-allocate variables for for-loop
delta_first  = zeros(size(ellipse_results));
delta_second = zeros(size(ellipse_results));
delta_third  = zeros(size(ellipse_results));
fprintf('Finally: Calculate strain... \n')

% 1.& 2. calculate area of the fit ellipse and from this assume a circle 
% with the same size to get the diameter of this circle
[axis_norm_first, axis_norm_second, axis_norm_third] = EllipseArea(ellipse_results);

% 3. Calculate strain at each point of the scanned region by going through
% all columns then all rows
for crow = 1:image_rows
    for ccol = 1:image_cols
        % Strain calculation according to e=delta_l/l_0, with the
        % separation between tension and compression side by the angle of
        % the ellipse for all three diffraction rings

        % first ring
        if ellipse_results{crow,ccol}{2,5}>1
            delta_first(crow,ccol) = (ellipse_results{crow,ccol}{2,2}-axis_norm_first(crow,ccol))/axis_norm_first(crow,ccol);% tension side
        else
            delta_first(crow,ccol) = (ellipse_results{crow,ccol}{2,1}-axis_norm_first(crow,ccol))/axis_norm_first(crow,ccol);% compression side
        end

        % second ring
        if ellipse_results{crow,ccol}{3,5}>1          
            delta_second(crow,ccol) = (ellipse_results{crow,ccol}{3,2}-axis_norm_second(crow,ccol))/axis_norm_second(crow,ccol);% tension side
        else
            delta_second(crow,ccol) = (ellipse_results{crow,ccol}{3,1}-axis_norm_second(crow,ccol))/axis_norm_second(crow,ccol);% compression side
        end

        % third ring
        if ellipse_results{crow,ccol}{4,5}>1
            delta_third(crow,ccol) = (ellipse_results{crow,ccol}{4,2}-axis_norm_third(crow,ccol))/axis_norm_third(crow,ccol);% tension side
        else                
            delta_third(crow,ccol) = (ellipse_results{crow,ccol}{4,1}-axis_norm_third(crow,ccol))/axis_norm_third(crow,ccol);% compression side
        end
    end
end

%% Optional quantitative results
% Calculated are the mean, max, std of the compression and tension side of
% all three planes. The results are saved in the given folder and printed.

%1. plane (10.0)
idx_tension        = delta_first >0 & delta_first<1; % threshold tension
idx_compression    = delta_first>-1 & delta_first<0; % threshold compression
max_tension_first  = max(delta_first(idx_tension),[],'all');
mean_tension_first = mean(delta_first(idx_tension));
std_tension_first  = std(delta_first(idx_tension));
max_comp_first     = min(delta_first(idx_compression),[],'all');
mean_comp_first    = mean(delta_first(idx_compression));
std_comp_first     = std(delta_first(idx_compression));

% 2.plane (00.2)
idx_tension         = delta_second >0 & delta_second<1; % threshold tension
idx_compression     = delta_second>-1 & delta_second<0; % threshold compression
max_tension_second  = max(delta_second(idx_tension),[],'all');
mean_tension_second = mean(delta_second(idx_tension));
std_tension_second  = std(delta_second(idx_tension));
max_comp_second     = min(delta_second(idx_compression),[],'all');
mean_comp_second    = mean(delta_second(idx_compression));
std_comp_second     = std(delta_second(idx_compression));

% 3. plane (10.1)
idx_tension        = delta_third >0 & delta_third<1; % threshold tension
idx_compression    = delta_third>-1 & delta_third<0; % threshold compression
max_tension_third  = max(delta_third(idx_tension),[],'all');
mean_tension_third = mean(delta_third(idx_tension));
std_tension_third  = std(delta_third(idx_tension));
max_comp_third     = min(delta_third(idx_compression),[],'all');
mean_comp_third    = mean(delta_third(idx_compression));
std_comp_third     = std(delta_third(idx_compression));

% put into one array and save it to folder location
mean_max_values = [max_tension_first mean_tension_first std_tension_first max_comp_first mean_comp_first std_comp_first max_tension_second mean_tension_second std_tension_second max_comp_second mean_comp_second std_comp_second max_tension_third mean_tension_third std_tension_third max_comp_third mean_comp_third std_comp_third];
writematrix(mean_max_values,[writepath sprintf('Mean_max_%d.txt',sample)]);

% Output to command window
fprintf('(10.0): max_tension= %.2d, mean_tension=%.2d +- %.2d\n',max_tension_first,mean_tension_first,std_tension_first)
fprintf('(10.0): max_comp= %.2d, mean_comp=%.2d +- %.2d\n',max_comp_first,mean_comp_first,std_comp_first)
fprintf('(00.2): max_tension= %.2d, mean_tension=%.2d +- %.2d\n',max_tension_second,mean_tension_second,std_tension_second)
fprintf('(00.2): max_comp= %.2d, mean_comp=%.2d +- %.2d\n',max_comp_second,mean_comp_second,std_comp_second)
fprintf('(10.1): max_tension= %.2d, mean_tension=%.2d +- %.2d\n',max_tension_third,mean_tension_third,std_tension_third)
fprintf('(10.1): max_comp= %.2d, mean_comp=%.2d +- %.2d\n',max_comp_third,mean_comp_third,std_comp_third)

%% Plot figures
% The three strain maps are plotted individually. To plot the maps nicely,
% it may be necessary to adjust the plotted area or flip the map!

%%% Optional plot adjustments %%%
% Flipping of map horizontally (to have all maps of all samples in the same
% direction)
delta_first  = flip(delta_first,2);
delta_second = flip(delta_second,2);
delta_third  = flip(delta_third,2);

% Adjust start and end of plotting (may be needed if too large regions were
% scanned)
start_x = 1;
end_x   = 30;
start_y = 1;
end_y   = 15;

%%% Plotting %%%
% Upper and lower limit of the plotted strains
xlimit_start =  -0.005;
xlimit_end   =  0.005;

% Position of plot window
width_figure=900;
shift_figure=500;

cbar_label='Strain';

% Create alpha map to remove background from plot
alpha_first=~isnan(delta_first);
alpha_second=~isnan(delta_second);
alpha_third=~isnan(delta_third);

% Image first ring
plane_1          = figure;
pos_plane_1      = plane_1.Position;
ax_first         = axes;
plane_1.Position = [pos_plane_1(1)-shift_figure pos_plane_1(2) width_figure/2 420];

image_first = imshow(delta_first(start_x:end_x,start_y:end_y),'InitialMagnification','fit');
set(image_first,'alphadata',alpha_first(start_x:end_x,start_y:end_y));
clim([xlimit_start xlimit_end])
set(ax_first,'FontSize',10)
ax_first.Visible = 'off';
colormap(ax_first,'parula');
title('(10.0) plane');

cbar_first                = colorbar(ax_first);
cbar_first.Label.String   = cbar_label;
pos_cbar_first            = cbar_first.Position;
cbar_first.Position       = [pos_cbar_first(1) pos_cbar_first(2) pos_cbar_first(3) pos_cbar_first(4)];
cbar_first.Label.FontSize = 10;

% Image second ring
plane_2          = figure;
pos_plane_2      = plane_2.Position;
ax_second        = axes;
plane_2.Position = [pos_plane_2(1) pos_plane_2(2) width_figure/2 420];

image_second = imshow(delta_second(start_x:end_x,start_y:end_y),'InitialMagnification','fit');
set(image_second,'alphadata',alpha_second(start_x:end_x,start_y:end_y));
clim([xlimit_start xlimit_end])
set(ax_second,'FontSize',10)
ax_second.Visible = 'off';
colormap(ax_second,'parula');
title('(00.2) plane');

cbar_second                = colorbar(ax_second);
cbar_second.Label.String   = cbar_label;
pos_cbar_second            = cbar_second.Position;
cbar_second.Position       = [pos_cbar_second(1) pos_cbar_second(2) pos_cbar_second(3) pos_cbar_second(4)];
cbar_second.Label.FontSize = 10;

% Image third ring
plane_3          = figure;
pos_plane_3      = plane_3.Position;
ax_third         = axes;
plane_3.Position = [pos_plane_3(1)+700 pos_plane_3(2) width_figure/2 420];


image_third = imshow(delta_third(start_x:end_x,start_y:end_y),'InitialMagnification','fit');
set(image_third,'AlphaData',alpha_third(start_x:end_x,start_y:end_y));
clim([xlimit_start xlimit_end])
set(ax_third,'FontSize',10)
ax_third.Visible = 'off';
colormap(ax_third,'parula');%map);
title('(10.1) plane');

cbar_third                = colorbar(ax_third);
cbar_third.Label.String   = cbar_label;
pos_cbar_third            = cbar_third.Position;
cbar_third.Position       = [pos_cbar_third(1) pos_cbar_third(2) pos_cbar_third(3) pos_cbar_third(4)];
cbar_third.Label.FontSize = 10;

% Export graphics
if exporting==1
    fprintf('Exporting figures...\n')

    exportgraphics(plane_1,[writepath sprintf('Cring%d_10-10Plane_strain_final.tif',sample)]);
    exportgraphics(plane_2,[writepath sprintf('Cring%d_0002Plane_strain_final.tif',sample)]);
    exportgraphics(plane_3,[writepath sprintf('Cring%d_10-11Plane_strain_final.tif',sample)]);
else
    fprintf('Exporting disabled...\n')
end
end

%% Additional functions

function [axis_norm_first, axis_norm_second, axis_norm_third]=EllipseArea(total_ellipse_results)
% function to calculate the area of the fit ellipse and determine its
% undeformed circular diffraction ring diameter

% Pre-allocate variables for for-loop: these are the theoretical undeformed
% diffraction ring diameters
axis_norm_first  = zeros(size(total_ellipse_results));
axis_norm_second = zeros(size(total_ellipse_results));
axis_norm_third  = zeros(size(total_ellipse_results));

% The for-loops go through all columns and then all rows of the scanned
% area to calculate the ellipse area at each scan point
for crow=1:size(total_ellipse_results,1)
    for ccol=1:size(total_ellipse_results,2)
        % calculate area of ellipse: ellipse fit gives the full length of
        % the axes, for the area the semiaxes (half the length of the full 
        % axes) is needed
        area_first  = pi*(total_ellipse_results{crow,ccol}{2,1}./2)*(total_ellipse_results{crow,ccol}{2,2}./2);
        area_second = pi*total_ellipse_results{crow,ccol}{3,1}/2*total_ellipse_results{crow,ccol}{3,2}/2;
        area_third  = pi*total_ellipse_results{crow,ccol}{4,1}/2*total_ellipse_results{crow,ccol}{4,2}/2;

        % assume area of ellipse is actually a circle and calculate radius
        % of this circle: this will be the new undeformed axis length
        axis_norm_first(crow,ccol)  = sqrt(area_first/pi)*2;
        axis_norm_second(crow,ccol) = sqrt(area_second/pi)*2;
        axis_norm_third(crow,ccol)  = sqrt(area_third/pi)*2;
    end
end
end