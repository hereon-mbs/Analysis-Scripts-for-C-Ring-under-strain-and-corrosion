function [distance, mean_first_line,mean_second_line,mean_third_line,std_first_line, std_second_line, std_third_line] = StrainDist_Line(delta_first,delta_second,delta_third,sample)
% Calculation of the line distribution of the strain in a C-ring. It is
% calculated for the vertical middle and its adjacent two lines above and
% two lines below.

px_size = 200; %µm

%% Find C-ring edges
% find start and end value of non-zero values
[y_pos_start,~] = find(delta_first(1:end-3,:)>0 | delta_first(1:end-3,:)<0,1);
if y_pos_start == 1
    [y_pos_start,~] = find(delta_first(2:end,:),1);
end
[~,x_pos_end] = find(delta_first(y_pos_start,:)>0 | delta_first(y_pos_start,:)<0,1,'last');

% adjust start and end value: row start is 3 lines below outermost point,
% col end is 2 lines after last non-zero point
x_pos_end   = x_pos_end+2;
y_pos_start = y_pos_start+5;

% if the previous limits are outside the sample boundaries, undo the
% adjustment
if x_pos_end>size(delta_first,2)
    x_pos_end = x_pos_end-2;
end


%% Calculate line plots for the first three diffraction rings
% Pre-define arrays
first_line  = zeros(x_pos_end,5);
second_line = zeros(x_pos_end,5);
third_line  = zeros(x_pos_end,5);
index       = 1;
index_row   = 1;
    
for crow = -2:2
    for ccol = 1:x_pos_end
        first_line(index,index_row)  = delta_first(y_pos_start+crow,ccol);
        second_line(index,index_row) = delta_second(y_pos_start+crow,ccol);
        third_line(index,index_row)  = delta_third(y_pos_start+crow,ccol);
        index=index+1;
    end
    index     = 1;
    index_row = index_row+1;
end

% Check if there are regions where some lines are already zero
for length = 1:size(first_line,1)
    if find(isnan(first_line(length,:)))>0
        first_line(length,:)  = NaN;
        second_line(length,:) = NaN;
        third_line(length,:)  = NaN;
    end
end

% Calculate mean and std of the lines
mean_first_line  = mean(first_line,2);
mean_second_line = mean(second_line,2);
mean_third_line  = mean(third_line,2);

std_first_line  = std(first_line,0,2);
std_second_line = std(second_line,0,2);
std_third_line  = std(third_line,0,2);


%% Calculate distance
% calculation of distance from px for proper visualization
distance         = double(mean_first_line);
[y_mean_start,~] = find(~isnan(mean_first_line),1);
[y_mean_end,~]   = find(~isnan(mean_first_line),1,'last');

for no_distances = 0:find(~isnan(mean_first_line),1,'last')-y_mean_start
    distance(y_mean_start+no_distances,1) = (no_distances)*px_size;
end
if y_mean_end<numel(mean_first_line)
    distance(y_mean_start+no_distances+1,1) = no_distances*px_size;
end

% Convert NaN to 0
mean_first_line(isnan(mean_first_line))   = 0;
mean_second_line(isnan(mean_second_line)) = 0;
mean_third_line(isnan(mean_third_line))   = 0;
distance(isnan(distance))                 = 0;

%% Adjust arrays
% The C-ring may start late with many zeros before. Here, they are removed
% along with potential Inf values due to calculations with NaN.

% delete inf values
mean_first_line(mean_first_line==inf)   = 0;
mean_second_line(mean_second_line==inf) = 0;
mean_third_line(mean_third_line==inf)   = 0;

array_size = nnz(mean_first_line);


% Adjust distance array: find where the first distance appears
start = find(distance,1);
if start<1
    start = 1;
end

% Find where the last distance entry ~= 0 appears. 
last_entry = find(distance==max(distance, [], 'all'),1);
if last_entry>(array_size+start)
    ende = array_size+start;
else
    ende = last_entry;
end

% Start the array one position before the first entry ~= 0
if start==1
    distance = distance(start:ende);
else
    distance = distance(start-1:ende);
end

% mean and std
start = find(mean_first_line,1);
if start<1
    start=1;
end

last_entry = find(mean_first_line,1,'last');
if last_entry>(array_size+start)
    ende = array_size+start;
else
    ende = last_entry;
end

mean_first_line  = mean_first_line(start:ende);
mean_second_line = mean_second_line(start:ende);
mean_third_line  = mean_third_line(start:ende);
std_first_line   = std_first_line(start:ende);
std_second_line  = std_second_line(start:ende);
std_third_line   = std_third_line(start:ende);

length_array = 9;

% if array is shorter than normal, additional entries are added
if size(distance,1)<length_array
        if max(distance, [], 'all') ==  1200
            adding = 2;
        elseif max(distance, [], 'all') == 1400
            adding = 1;
        end

    distance(end+1:end+adding,1)         = 0;
    mean_first_line(end+1:end+adding,1)  = 0;
    mean_second_line(end+1:end+adding,1) = 0;
    mean_third_line(end+1:end+adding,1)  = 0;
    std_first_line(end+1:end+adding,1)   = 0;
    std_second_line(end+1:end+adding,1)  = 0;
    std_third_line(end+1:end+adding,1)   = 0;
end

% in case the array is longer than normal, additional values are deleted
if max(distance, [], 'all')>1600
    deleting = 9;

    distance         = distance(1:deleting);
    mean_first_line  = mean_first_line(1:deleting);
    mean_second_line = mean_second_line(1:deleting);
    mean_third_line  = mean_third_line(1:deleting);
    std_first_line   = std_first_line(1:deleting);
    std_second_line  = std_second_line(1:deleting);
    std_third_line   = std_third_line(1:deleting);
end

end