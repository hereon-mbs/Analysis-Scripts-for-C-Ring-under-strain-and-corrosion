function [ellipse_results] = FitEllipse_DiffractionPattern(threshold_first, threshold_second, threshold_third, image_rows, image_cols)
% Fitting an ellipse to the diffraction pattern of deformed C-rings
%   1. find location, where material was found (to save computation time)
%   2. fit ellipse of the first three diffraction rings and save fit
%      results to variable
%   3. if no material is at the current location, NaN is inserted in
%      results

% Pre-allocation of variables for for-loop
ellipse_results = cell(image_rows,image_cols);
index_images    = 1;
image_first     = NaN(image_rows,image_cols);
image_second    = NaN(image_rows,image_cols);
image_third     = NaN(image_rows,image_cols);

fprintf('Fit ellipses...\n')
% Going through all the columns then rows of the scanned region to
% fit the ellipses
for crow=1:image_rows
    for ccol=1:image_cols
        % 1. Save x and y coordinates of thresholded pixel
        [y_first, x_first]   = find(threshold_first(:,:,index_images));
        [y_second, x_second] = find(threshold_second(:,:,index_images));
        [y_third, x_third]   = find(threshold_third(:,:,index_images));
        
        if numel(y_first)>4
            % 2. Fit ellipse to the three diffraction rings
            [semimajor_first, semiminor_first, x0_first, y0_first, phi_first]      = ellipse_fit(x_first,y_first);
            [semimajor_second, semiminor_second, x0_second, y0_second, phi_second] = ellipse_fit(x_second,y_second);
            [semimajor_third, semiminor_third, x0_third, y0_third, phi_third]      = ellipse_fit(x_third,y_third);

            intermed_results=[real(semimajor_first),real(semiminor_first),real(x0_first),real(y0_first),real(phi_first)
                              real(semimajor_second),real(semiminor_second),real(x0_second),real(y0_second),real(phi_second)
                              real(semimajor_third),real(semiminor_third),real(x0_third),real(y0_third),real(phi_third)];
            
            image_first(crow,ccol)  = real(semimajor_first);
            image_second(crow,ccol) = real(semimajor_second);
            image_third(crow,ccol)  = real(semimajor_third);
        else
            % 3. no material is found in this location
            intermed_results = [NaN,NaN,NaN,NaN,NaN
                                NaN,NaN,NaN,NaN,NaN
                                NaN,NaN,NaN,NaN,NaN];
            image_first(crow,ccol)  = NaN;
            image_second(crow,ccol) = NaN;
            image_third(crow,ccol)  = NaN;
        end
    
        % Save results in cell array
        header_results   = {'Semimajor axis', 'Semiminor axis', 'X0', 'Y0','Phi'};
        intermed_results = num2cell(real(intermed_results));
        ellipse_results(crow,ccol) = {[header_results; intermed_results]};
        index_images = index_images+1;
    end
    clear semimajor_first semiminor_first x0_first y0_first phi_first semimajor_second semiminor_second x0_second y0_second phi_second semimajor_third semiminor_third x0_third y0_third phi_third
end
end