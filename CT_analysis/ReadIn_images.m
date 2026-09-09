function [specimen] = ReadIn_images(filepath, StartImage, EndImage)
% This function loads all images that are in the given folder location. To
% specify only a certain range of images, start and end numbers of images
% can be given.

warning('off','all')

% was a starting image given?
if ~exist('StartImage','var')
    StartImage = 1;
end

% find all files with .tif ending 
dir_files = dir([filepath '*.tif']);
dir_files = {dir_files(:).name};
num_files = numel(dir_files);

% was an ending image number given?
if ~exist('EndImage','var')
    EndImage = num_files;
end

% read all images
parfor i = StartImage:EndImage
    specimen(:,:,i) = imread(cell2mat(dir_files(i)));
end
end