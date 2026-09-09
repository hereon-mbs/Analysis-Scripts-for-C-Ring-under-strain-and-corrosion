function StrainMap_LinePlot_Overview
% Plotted are the strain distribution line plots of one deformation over
% all given time points


close all
% to-be adjusted
deformation = 70;
time_points = 5;
export      = 0;

% where is the saved data?
filepath='';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Script %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pre-allocate variables
total_mean     = nan(20,5,3); % points, degradation, plane
total_std      = nan(20,5,3); % points, degradation, plane
total_distance = nan(20,5);


for degradation=0:time_points-1
    %% Load data
    %%%% mean data %%%%
    loaded_mean   = load([filepath sprintf('Lineplots_mean_%d%%_%d_weeks_final.mat', deformation, degradation)]);
    intermed_mean =loaded_mean.mean_line;
    
    
    %%%% std data %%%%
    loaded_std   = load([filepath sprintf('Lineplots_std_%d%%_%d_weeks_final.mat', deformation, degradation)]);
    intermed_std = loaded_std.std_line;
    
    %%%% distance %%%%
    loaded_distance   = load([filepath sprintf('Lineplots_distance_%d%%_%d_weeks_final.mat', deformation, degradation)]);
    intermed_distance = loaded_distance.distance_line;
    step_distance     = (intermed_distance(5,1)-intermed_distance(4,1))/2;
    intermed_distance = intermed_distance(2:end-1)+step_distance;

    %%%% delete -2 and 0 values %%%%
    intermed_mean(intermed_mean==-2)        = NaN;
    intermed_mean(intermed_mean==0)         = NaN;
    intermed_std(intermed_std==0)           = NaN;
    intermed_distance(intermed_distance==0) = NaN;
    
    % Concatenate the time point results
    total_mean(1:size(intermed_mean,1)-2,degradation+1,1)     = intermed_mean(2:end-1,:,1);
    total_mean(1:size(intermed_mean,1)-2,degradation+1,2)     = intermed_mean(2:end-1,:,2);
    total_mean(1:size(intermed_mean,1)-2,degradation+1,3)     = intermed_mean(2:end-1,:,3);
    total_std(1:size(intermed_mean,1)-2,degradation+1,1)      = intermed_std(2:end-1,:,1);
    total_std(1:size(intermed_mean,1)-2,degradation+1,2)      = intermed_std(2:end-1,:,2);
    total_std(1:size(intermed_mean,1)-2,degradation+1,3)      = intermed_std(2:end-1,:,3);
    total_distance(1:size(intermed_mean,1)-2,degradation+1,:) = intermed_distance;
end

%% Adjust arrays
total_mean_fill     = total_mean;
total_std_fill      = total_std;
total_distance_fill = total_distance;

total_mean_fill(isnan(total_mean))         = 0;
total_std_fill(isnan(total_std))           = 0;
total_distance_fill(isnan(total_distance)) = 0;

%% Plot results
colors = lines(5);
marker='^v><d';

% First plane
lineplot_first = figure;
ax_line_first  = axes;

hold on
for condition = 1:5
    for steps = 1:size(total_distance,1)
        step_distance = (total_distance(5,condition)-total_distance(4,condition))/2;
        xl = total_distance_fill(steps,condition)-step_distance;
        xr = total_distance_fill(steps,condition)+step_distance;
        yu = total_mean_fill(steps,condition,1)-total_std_fill(steps,condition,1);
        yo = total_mean_fill(steps,condition,1)+total_std_fill(steps,condition,1);
        % Errorbars
        fill([xl;xr;xr;xl],[yu;yu;yo;yo],colors(condition,:),'FaceAlpha',0.4,'LineStyle','none','HandleVisibility','off')
    end
    % Results
    plot(total_distance(:,condition),total_mean(:,condition,1),marker(condition),'MarkerEdgeColor',colors(condition,:),'MarkerFaceColor',colors(condition,:),'MarkerSize',14)
end

% Line at 0
plot(-50:50:1800,zeros(size(-50:50:1800,2)),'LineWidth',2,'Color',[0.8500 0.3250 0.0980]) 
hold off
ylim([-5 5]*10^(-3))
yticks(-5*10^(-3):2*10^(-3):5*10^(-3))
xticks(0:200:1800)
xlim([-50 1800])
xlabel('Distance / µm')
ylabel('Strain')
legend('0 weeks', '1 week', '2 weeks','3 weeks', '4 weeks','Location','northeast')
set(ax_line_first,'FontSize',22)

% Second plane
lineplot_second = figure;
ax_line_second  = axes;
hold on
for condition=1:5
    for steps=1:size(total_distance,1)
        step_distance = (total_distance(5,condition)-total_distance(4,condition))/2;
        xl = total_distance_fill(steps,condition)-step_distance;
        xr = total_distance_fill(steps,condition)+step_distance;
        yu = total_mean_fill(steps,condition,2)-total_std_fill(steps,condition,2);
        yo = total_mean_fill(steps,condition,2)+total_std_fill(steps,condition,2);
        % Errorbars
        fill([xl;xr;xr;xl],[yu;yu;yo;yo],colors(condition,:),'FaceAlpha',0.4,'LineStyle','none','HandleVisibility','off');
    end

    % Results
    plot(total_distance(:,condition),total_mean(:,condition,2),marker(condition),'MarkerEdgeColor',colors(condition,:),'MarkerFaceColor',colors(condition,:),'MarkerSize',14)
end

% Line at 0
plot(-50:50:1800,zeros(size(-50:50:1800,2)),'LineWidth',2.5,'Color',[0.8500 0.3250 0.0980]) 
hold off
ylim([-5 5]*10^(-3))
yticks(-5*10^(-3):2*10^(-3):5*10^(-3))
xticks(0:200:1800)
xlim([-50 1800])
xlabel('Distance / µm')
ylabel('Strain')
legend('0 weeks', '1 week', '2 weeks', '3 weeks', '4 weeks', 'Location','northeast')
set(ax_line_second,'FontSize',22)

% Third plane
lineplot_third = figure;
ax_line_third  = axes;

hold on
for condition=1:5
    for steps=1:size(total_distance,1)
        step_distance = (total_distance(5,condition)-total_distance(4,condition))/2;
        xl = total_distance_fill(steps,condition)-step_distance;
        xr = total_distance_fill(steps,condition)+step_distance;
        yu = total_mean_fill(steps,condition,3)-total_std_fill(steps,condition,3);
        yo = total_mean_fill(steps,condition,3)+total_std_fill(steps,condition,3);
        % Errorbars
        fill([xl;xr;xr;xl],[yu;yu;yo;yo],colors(condition,:),'FaceAlpha',0.4,'LineStyle','none','HandleVisibility','off');
    end

    % Results
    plot(total_distance(:,condition),total_mean(:,condition,3),marker(condition),'MarkerEdgeColor',colors(condition,:),'MarkerFaceColor',colors(condition,:),'MarkerSize',14)
end

% Line at 0
plot(-50:50:1800,zeros(size(-50:50:1800,2)),'LineWidth',2.5,'Color',[0.8500 0.3250 0.0980])
hold off
ylim([-5 5]*10^(-3))
yticks(-5*10^(-3):2*10^(-3):5*10^(-3))
xticks(0:200:1800)
xlim([-50 1800])
xlabel('Distance / µm')
ylabel('Strain')
legend('0 weeks', '1 week', '2 weeks', '3 weeks', '4 weeks', 'Location','northeast')
set(ax_line_third,'FontSize',22)

if export==1
    exportgraphics(lineplot_first,[filepath sprintf('Lineplot_dots_overview_%d_1010Plane.png',deformation)]);
    exportgraphics(lineplot_second,[filepath sprintf('Lineplot_dots_overview_%d_0002Plane.png',deformation)]);
    exportgraphics(lineplot_third,[filepath sprintf('Lineplot_dots_overview_%d_1011Plane.png',deformation)]);
end
end