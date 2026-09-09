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