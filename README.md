# Analysis-Scripts-for-C-Ring-under-strain-and-corrosion

The following scripts have been developed to analyze the strain distribution in C-rings that were investigated by scanning 2D XRD and laboratory µCT. The related paper [1] offers additional details on the potential analyses. The analysis is divided into three parts:
1.	Calculate the strain maps from the scanning 2D XRD
2.	Calculate and average the strain distribution over samples of the same condition
3.	Differentiation between tensile and compressive strain regions of µCT scans and calculation of degradation parameters

   
Strain Maps
The 2D XRD analysis scripts are optimized for Mg-based alloys, as only three diffraction rings are analyzed. 
Due to the C-ring sample geometry, the strains vary depending on the position in the C-ring. Furthermore, strain anisotropy occurs. Therefore, standard radial integration of the diffraction pattern is not possible. In this approach, individual diffraction rings are fit with ellipses, from which strain is calculated using the semimajor axis length. It is assumed that an applied deformation leads to a distortion of the diffraction rings that is directly related to the applied strain. The calculation is based on e = delta_l/l_0, where l_0 is determined by first calculating the ellipse area. Under the assumption that the undeformed diffraction ring has the same area, the diameter of the undeformed diffraction ring is calculated and set as l_0. 
To save computation time, the ellipse fits and images are saved as .mat-files.

Procedure:
1.	The main function is Scanning_2DXRD_StrainMaps
2.	Before the calculation is possible, masks for the three diffraction rings have to be created manually (e.g., using Fiji)
  a.	Mask_inside_first: masks out only the primary beam
  b.	Mask_outside_first: primary beam & first ring are visible
  c.	Mask_outside_second: primary beam, first ring & second ring are visible
  d.	Mask_outside_third: primary beam, first ring, second ring & third ring are visible
3.	The following information is needed to proceed: 
  a.	sample: the sample number (integer)
  b.	filepath: where are all (!) the samples located (e.g. the raw folder)
  c.	writepath: where should the results be saved
  d.	image_rows: the scan height in px (needed to create a 2D map)
  e.	image_cols: the scan width in px (needed to create a 2D map)
4.	in addition to the main function, the following functions are needed:
  a.	ReadIn_images: loads all images of the sample in the given filepath. It is possible to set a starting and end image number if not all images are needed or wanted
  b.	FitEllipse_DiffractionPattern: this is the main function of fitting an ellipse to the first three diffraction rings and saving the results at the specific location in the map
  c.	ellipse_fit: from [2] fits an ellipse to the diffraction ring

Troubleshooting:
If the fitting is not working properly, the threshold can be adjusted. 
If the plotted map is shifted, the plotted region can be adjusted or the map can be flipped horizontally.

Average strain distribution line
To quantify the strain over the width of the C-ring over all samples of the same condition, the samples have to be registered and potentially cropped. The line distribution is calculated from the vertical middle row with two adjacent rows above and below this region. 
Procedure:
1.	The main script StrainMap_LinePlot averages over all samples of the same condition but can be run for one sample only. In that case, the following step has to be adapted to show only one sample for the chosen condition
2.	For easy repetition, the script is designed such that all potential samples have been added as an array, as shown below:
	Samples = [20 21 22]; gives the sample number
	samples_deg = [1 1 1]; degradation time of the three samples given in samples
	samples_def = [70 70 70]; deformation of the three samples given in samples
3.	Before running the script, the sample information have to be added in addition to the filepath and the writepath. Which condition is to be analyzed has to be given by defining degradation and deformation. 
4.	The script loads the previously determined ellipse results and calculates the strain according to the Strain Map script.
5.	The main averaging is done in StrainDist_Line, where the samples are registered to the first sample (and potentially cropped)
6.	Furthermore, the distance is calculated: here, the pixel size needs to be adjusted to the correct one
7.	To be able to plot an overview of the line plots over different times, export_mean has to be set to 1
8.	Running the script StrainMap_LinePlot_Overview gives all time points of the same deformation in one plot. Here, the filepath has to be given and the wanted deformation

µCT Analysis
To investigate the differences in degradation behavior depending on tensile or compressive deformation, deformed and degraded C-rings are scanned using µCT. Calculated are the overall degradation rate and mean degradation depth,  and the mean degradation depth and pitting factor (in 2D and 3D) for the tensile and compressive sides. For this analysis, initial and degraded µCT scans are required that are both segmented and registered. For the degraded sample, the following labels are needed: degradation layer, residual material, and surrounding. 
Procedure:
1.	The main function is Strain_DegradationAnalaysis
2.	Further scripts needed, ReadIn_images, contact_area [3]
3.	The following information have to be added:
  a.	Sample: sample number/name
  b.	voxel_size: voel size in µm
  c.	filepath: file path where all samples are located (e.g., the reco folder)
  d.	Folder_name: folder name where the segmented images are located
4.	Once, the sample_numbers, sample_deformations, and sample_degradations have to be added to be able to run the script for all applicable samples (similar to the previous scripts)
5.	The separation of tensile and compressive side is based on a surface determination. As this calculation is time consuming, the results are exported in the filepath.
Troubleshooting:
•	Loading of segmented images not working: check if the filepath is determined correctly
•	Degradation parameter unrealistic: have the pixel values of degradation, residual material, surrounding correctly been assigned?

References
[1] 
[2] Tal Hendel (2026). Ellipse Fit (https://de.mathworks.com/matlabcentral/fileexchange/22423-ellipse-fit), MATLAB Central File Exchange. Abgerufen 8. September 2026. 
[3] Julian Moosmann, https://github.com/moosmann/matlab/blob/master/matlab/utilities/contact_area.m
