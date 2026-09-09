function StrainMap_LinePlot
% Calculate the mean strain over the width of the sample. Taken are the 5 
% lines above and below the middle of the sample. This is done for all
% samples of the same condition. Needed are the ellipse results of the
% Scanning_2DXRD_StrainMaps script.

close all

% do you want the results to be exported and saved?
export=0; % export plots: 1=yes, 0=no
export_mean=0; % export results of line plots (mean, std, distance): 1=yes, 0=no

% which degradation and deformation should be analyzed?
degradation=1; 
deformation=70;

% where should the results be saved?
writepath = '/asap3/spec.instruments/gpfs/nanotom/2021/data/11012032/processed/Birte_C-Rings/Strainmapping XRD/Results_test/';

%%%%%%%%%%%%%%%%%%% Calculations %%%%%%%%%%%%%%%%%%%%%%%%

%% Determine all samples of same condition
% define all the samples and their condition (values are just examples)
filepath    = '/asap3/spec.instruments/gpfs/nanotom/2021/data/11012032/processed/Birte_C-Rings/Strainmapping XRD/Results/'; % where are the fit ellipse results
samples     = [20 21 22]; % what are the sample names
samples_deg = [1  1  1]; % which degradation time do the samples have
samples_def = [70 70 70]; % which deformation do the samples have

% Find all samples of the same condition
matches_samples = samples(samples_def==deformation & samples_deg==degradation);
total_samples   = numel(matches_samples);

fprintf('%d samples were found for %d %% deformation after %d weeks \n', total_samples, deformation, degradation)

%% Read results
% Read matching samples: samples have to be registered, cropped & flipped 
% to be concatenated

% Pre-allocate variable
total_ellipse_results = {};

[total_ellipse_results] = Loading_results(filepath, matches_samples, total_ellipse_results);

%% Calculate strain and line plots
% The calculation is based on the method in Scanning_2DXRD_StrainMaps
total_normalized_first  = zeros(size(total_ellipse_results));
total_normalized_second = zeros(size(total_ellipse_results));
total_normalized_third  = zeros(size(total_ellipse_results));

% Calculate the equivalent circle radius
for sample = 1:size(total_ellipse_results,3)
    [total_normalized_first(:,:,sample), total_normalized_second(:,:,sample), total_normalized_third(:,:,sample)] = EllipseArea(total_ellipse_results(:,:,sample));
end

length_line=9;

% Pre-allocate variables
delta_first     = zeros(size(total_ellipse_results));
delta_second    = zeros(size(total_ellipse_results));
delta_third     = zeros(size(total_ellipse_results));
total_distance  = zeros(length_line,total_samples,1);
total_line_mean = zeros(length_line,total_samples,3);
total_line_std  = zeros(length_line,total_samples,3);


for sample=1:total_samples
    for crow=1:size(total_ellipse_results,1)
        for ccol=1:size(total_ellipse_results,2)
            % Strain calculation according to e=delta_l/l_0, with the
            % separation between tension and compression side by the angle of
            % the ellipse for all three diffraction rings

            % first ring
            if total_ellipse_results{crow,ccol,sample}{2,5}>1
                delta_first(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{2,2}-total_normalized_first(crow,ccol,sample))/total_normalized_first(crow,ccol,sample);% tension
            else
                delta_first(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{2,1}-total_normalized_first(crow,ccol,sample))/total_normalized_first(crow,ccol,sample);% compression
            end

            % second ring
            if total_ellipse_results{crow,ccol,sample}{3,5}>1          
                delta_second(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{3,2}-total_normalized_second(crow,ccol,sample))/total_normalized_second(crow,ccol,sample);
            else
                delta_second(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{3,1}-total_normalized_second(crow,ccol,sample))/total_normalized_second(crow,ccol,sample);
            end

            % third ring
            if total_ellipse_results{crow,ccol,sample}{4,5}>1
                delta_third(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{4,2}-total_normalized_third(crow,ccol,sample))/total_normalized_third(crow,ccol,sample);
            else                
                delta_third(crow,ccol,sample) = (total_ellipse_results{crow,ccol,sample}{4,1}-total_normalized_third(crow,ccol,sample))/total_normalized_third(crow,ccol,sample);
            end
        end
    end

    % calculate line plot
    fprintf('Calculating mean and std plot... \n')
[total_distance(:,sample,1), total_line_mean(:,sample,1),total_line_mean(:,sample,2),total_line_mean(:,sample,3),total_line_std(:,sample,1), total_line_std(:,sample,2), total_line_std(:,sample,3)] = StrainDist_Line(delta_first(:,:,sample),delta_second(:,:,sample),delta_third(:,:,sample),matches_samples(sample));
end

%% Average over all samples

% Pre-allocate variables
mean_line     = zeros(length_line+2,1,total_samples);
std_line      = zeros(length_line+2,1,total_samples);
distance_line = zeros(length_line+1,1);

% calculate mean and std values: for better visualization a 0 is added as
% first and last value
for sample = 1:3
    mean_line(2:end-1,:,sample) = mean(total_line_mean(:,:,sample),2,'omitnan');
    std_line(2:end-1,:,sample)  = mean(total_line_std(:,:,sample),2,'omitnan');
end

[~,max_distance_col]   = find(total_distance==max(total_distance, [], 'all'),1);
distance_line(2:end,:) = total_distance(:,max_distance_col);

% adjust start and end values of mean values
mean_line(mean_line==0) = -2;

% find positions after half the distance which are 0 to convert them to max
% value (should only be the last values)
pos_distances_zero = find(distance_line(size(distance_line,1)/2:end,1)==0);
pos_distances_zero = pos_distances_zero+size(distance_line,1)/2-1;
distance_line(pos_distances_zero) = max(total_distance, [], 'all');
distance_line(end+1,1)            = distance_line(end,1);

%% Plot results
% First plane
lineplot_first = figure;
ax_line_first  = axes;

hold on
plot(distance_line(:,1,1),zeros(size(mean_line(:,:,1),1)),'LineWidth',2.5,'Color',[0.8500 0.3250 0.0980]) % Line at 0
fill([distance_line(:,:,1);flipud(distance_line(:,1,1))],[mean_line(:,:,1)-std_line(:,:,1);flipud(mean_line(:,:,1)+std_line(:,:,1))],[0 0.4470 0.7410],'FaceAlpha',0.4,'LineStyle','none');
plot(distance_line(:,1,1),mean_line(:,:,1),'LineWidth',2.5,'Color',[0 0.4470 0.7410])
hold off

ylim([-0.01 0.01])
xticks(0:400:1600)
xlim([-20 1620])
xlabel('Distance / µm')
ylabel('Strain')
set(ax_line_first,'FontSize',20)

% Second plane
lineplot_second = figure;
ax_line_second  = axes;

hold on
plot(distance_line(:,:,1),zeros(size(mean_line(:,:,2),1)),'LineWidth',2.5,'Color',[0.8500 0.3250 0.0980]) % Line at 0
fill([distance_line(:,:,1);flipud(distance_line(:,:,1))],[mean_line(:,:,2)-std_line(:,:,2);flipud(mean_line(:,:,2)+std_line(:,:,2))],[0 0.4470 0.7410],'FaceAlpha',0.4,'LineStyle','none');
plot(distance_line(:,:,1),mean_line(:,:,2),'LineWidth',2.5,'Color',[0 0.4470 0.7410])
hold off

ylim([-0.01 0.01])
yticks(-2:1:2)
xticks(0:400:1600)
xlim([-20 1620])
xlabel('Distance / µm')
ylabel('Strain')
set(ax_line_second,'FontSize',20)

% Third plane
lineplot_third = figure;
ax_line_third  = axes;

hold on
plot(distance_line(:,:,1),zeros(size(mean_line(:,:,3),1)),'LineWidth',2.5,'Color',[0.8500 0.3250 0.0980]) % Line at 0
fill([distance_line(:,:,1);flipud(distance_line(:,:,1))],[mean_line(:,:,3)-std_line(:,:,3);flipud(mean_line(:,:,3)+std_line(:,:,3))],[0 0.4470 0.7410],'FaceAlpha',0.4,'LineStyle','none');
plot(distance_line(:,:,1),mean_line(:,:,3),'LineWidth',2.5,'Color',[0 0.4470 0.7410])
hold off

ylim([-0.01 0.01])
xticks(0:400:1600)
xlim([-20 1620])
xlabel('Distance / µm')
ylabel('Strain')
set(ax_line_third,'FontSize',20)

%% Export results
if export_mean==1
    save(fullfile([writepath 'Lineplots_data/'],sprintf('Lineplots_mean_%d%%_%d_weeks_final.mat',deformation, degradation)),'mean_line','-v7.3');
    save(fullfile([writepath 'Lineplots_data/'],sprintf('Lineplots_std_%d%%_%d_weeks_final.mat',deformation, degradation)),'std_line','-v7.3');
    save(fullfile([writepath 'Lineplots_data/'],sprintf('Lineplots_distance_%d%%_%d_weeks_final.mat',deformation, degradation)),'distance_line','-v7.3');
end

if export==1
    fprintf('Exporting figures...\n')
    if average_map==1
        exportgraphics(plane_1,[writepath sprintf('Average_Strain_%d%%_%d weeks_10-10Plane.tif',deformation, degradation)]);
        exportgraphics(plane_2,[writepath sprintf('Average_Strain_%d%%_%d weeks_0002Plane_.tif',deformation, degradation)]);
        exportgraphics(plane_3,[writepath sprintf('Average_Strain_%d%%_%d weeks_10-11Plane.tif',deformation, degradation)]);
    end
    exportgraphics(lineplot_first,[writepath sprintf('Lineplot_%d%%_%d weeks_10-10Plane.png',deformation, degradation)]);
    exportgraphics(lineplot_second,[writepath sprintf('Lineplot_%d%%_%d weeks_0002Plane.png',deformation, degradation)]);
    exportgraphics(lineplot_third,[writepath sprintf('Lineplot_%d%%_%d weeks_10-11Plane.png',deformation, degradation)]);
else
    fprintf('Exporting disabled...\n')
end
end

%% Additional functions

function [total_ellipse_results] = Loading_results(beamtime, matches, total_ellipse_results)
% Load all results of the given samples of the same condition

%% Load results
% Load ellipse_results of the first sample and add it to the result array
loaded_ellipse_results = load([beamtime sprintf('Ellipse_results_%d.mat',matches(1))]);
loaded_image_first     = load([beamtime sprintf('Image_first_%d.mat',matches(1))]);
total_ellipse_results  = loaded_ellipse_results.ellipse_results;
total_image_first      = loaded_image_first.image_first;

% if a sample has to be flipped, adjust the condition
if contains(beamtime, 'Strainmapping XRD')==1
    total_ellipse_results = flip(total_ellipse_results,2);
    total_image_first     = flip(total_image_first,2);
end

% Crop image to have consitent image size. (All beamtimes have
% different image sizes which leads to difficulties in the registering)
[total_ellipse_results, total_image_first]=Cropping_maps(total_ellipse_results, total_image_first);

if matches>1
    for n = 2:numel(matches)
        % Load ellipse_results
        loaded_ellipse_results = load([beamtime sprintf('Ellipse_results_%d.mat',matches(n))]);
        inter_ellipse_results  = loaded_ellipse_results.ellipse_results;
        loaded_image_first     = load([beamtime sprintf('Image_first_%d.mat',matches(n))]);
        inter_image_first      = loaded_image_first.image_first;
        
        % if a sample has to be flipped, adjust the condition
        if contains(beamtime, 'Strainmapping XRD')==1
            inter_ellipse_results=flip(inter_ellipse_results,2);
            inter_image_first=flip(inter_image_first,2);
        end

        %% Register images
        % The samples are not necessarily starting at the same position. To
        % average over all samples, they have to be registered to correctly
        % fit the same locations at the same position.
        [inter_ellipse_results] = RegisterImages(inter_ellipse_results, inter_image_first, total_ellipse_results(:,:,1), total_image_first(:,:,1));
        inter_ellipse_results   = inter_ellipse_results(1:size(total_ellipse_results,1), 1:size(total_ellipse_results,2));
        total_ellipse_results   = cat(3,total_ellipse_results, inter_ellipse_results);
    end
end
end

function [inter_ellipse_results, inter_image_first] = Cropping_maps(inter_ellipse_results, inter_image_first)
% Cropping of the image to have consistent image sizes

% define the rows to be selected
if size(inter_image_first,1)>16
    [row_start,~] = find(inter_image_first(1:end-4,:)>1,1);
    if row_start<=2
        start_x = 1;
        end_x   = 16;
    else
        start_x = row_start-2;
        end_x   = start_x+15;
    end
else
    start_x = 1;
    end_x   = 16;
end

% define the columns to be selected
if size(inter_image_first,2)>26
    [~,col_start] = find(inter_image_first(start_x,1:end-4)>1,1);
    if col_start<=2
        start_y = 1;
        end_y   = 26;
    else
        start_y = col_start-2;
        end_y   = start_y+25;
    end
else
    start_y = 1;
    end_y   = 26;
end

inter_ellipse_results = inter_ellipse_results(start_x:end_x,start_y:end_y);
inter_image_first     = inter_image_first(start_x:end_x,start_y:end_y);
end

function [shifted_inter] = RegisterImages(inter_ellipse_results, inter_image_first, first_ellipse_results, first_image_first)
% The samples need to be registered to average over the whole width

%%%%%%%%% Register the samples to each other %%%%%%%%%%%%%%%%
fprintf('Registering and calculating transformation...\n')

% defining cells to be added
added_cell = {'Semimajor axis', 'Semiminor axis', 'X0', 'Y0', 'Phi'
                NaN, NaN, NaN, NaN, NaN
                NaN, NaN, NaN, NaN, NaN
                NaN, NaN, NaN, NaN, NaN};

% Calculate transformation by finding first column where there's a non-zero
% pixel for first match
image_rowcol = size(first_ellipse_results,1);

[row_position_def,col_position_def]     = find(first_image_first(1:image_rowcol,:)>1,1);
[row_position_inter,col_position_inter] = find(inter_image_first(1:end-3,:)>1,1);

% for some images it's possible that the opening of the c (the ends of the 
% sample) appear near the end of the image: image is only analyzed for 2/3 
if size(inter_image_first,2)>41
    last_col = round(size(inter_image_first,2)*2/3);
else
    last_col = size(inter_image_first,2);
end

if find(isnan(inter_image_first(row_position_inter,col_position_inter:last_col)),1)<find(inter_image_first(row_position_inter,col_position_inter:last_col)>0,1,'last')
    % find position where after this wrongly detected px NaN is again
    [~,start_search] = find(isnan(inter_image_first(row_position_inter,col_position_inter:end-1)), 1);
    [row_position_inter,col_position_new] = find(inter_image_first(1:end-4,start_search+col_position_inter:end)>1,1);
    col_position_inter = col_position_inter+col_position_new+start_search-1;
end

col_translation = col_position_def-col_position_inter;
row_translation = row_position_def-row_position_inter;
fprintf(sprintf('The x translation is by %d pixel. \n', col_translation))
fprintf(sprintf('The y translation is by %d pixel. \n', row_translation))

if col_translation >=image_rowcol || row_translation >= image_rowcol
    fprintf('<strong> Attention:</strong> registering failed! Translation larger than image!\n')
else
    fprintf('Registering successful...\n')
end

% delete all entries before the start of the sample
inter_ellipse_results(:,1:col_position_inter-1) = {added_cell};

% Shift control results to fit deformed image
shifted_rows        = cell(size(inter_ellipse_results));
shifted_inter       = cell(size(inter_ellipse_results));

% if there is no translation needed, the previous shift would lead to
% negative shift
if row_translation == -1
    row_translation = 0;
elseif col_translation == -1
    col_translation = 0;
end

% shift the image along the rows according to the calculated translation
if row_translation > 0
    shifted_rows(row_translation+1:end,:)       = inter_ellipse_results(1:end-row_translation,:);
elseif row_translation == 0
    shifted_rows       = inter_ellipse_results;
elseif row_translation < 0
    shifted_rows(1:end+row_translation,:)       = inter_ellipse_results(abs(row_translation)+1:end,:);
end

% shift the image along the columns according to the calculated translation
if col_translation > 0
    shifted_inter(:,col_translation+1:end)       = shifted_rows(:,1:end-col_translation);
elseif col_translation == 0
    shifted_inter       = shifted_rows;
elseif col_translation < 0
    shifted_inter(:,1:end+col_translation)       = shifted_rows(:,abs(col_translation)+1:end);
end

empty_cells = cellfun(@isempty, shifted_inter);
shifted_inter(empty_cells) = {added_cell};
end