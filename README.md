# TrackingAndLocalizationULM
This is the joint repository for the paper : [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (IEEE TMI:10.1109/TMI.2024.3456676 )](https://ieeexplore.ieee.org/document/10669597)

## If you use the code, please cite the corresponding papers:

- [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (IEEE TMI:10.1109/TMI.2024.3456676)](https://ieeexplore.ieee.org/document/10669597)
- [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)
- [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)

## RELATED DATASET:

The in vivo mouse brain dataset of the article is available upon request.


# Installation 

## Cloning the repository
 This repository contains submodules so use : 

`git clone --recurse-submodules git@github.com:provostultrasoundlab/TrackingAndLocalizationULM.git`

**Note:**  
Cloning via SSH requires that you have a valid SSH key configured with your GitHub account. If you have not set up SSH keys, follow [GitHub's guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) before cloning.

Here is the list of the different submodules : 
- `BEGPUThinning.git` : [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)
- `JermanEnhancementFilter.git` : [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)

**Note:** 

`BEGPUThinning` had compilation issues, so we resolved them by creating a fork of the repository. This fork is now included as a submodule in the project.

## Compilation GPU functions 

### Advice

To use these functions in Matlab, you need to download the appropriate [CUDA toolkit version for your version of Matlab](https://www.mathworks.com/help/releases/R2024a/parallel-computing/run-mex-functions-containing-cuda-code.html).

It is recommended to use Microsoft Visual Studio 2019 as the compiler (Important for mexcuda). You may find the installer here: [click here](https://quasar.ugent.be/files/doc/cuda-msvc-compatibility.html).  
To select the compiler in Matlab, run:

```matlab
mex -setup C++
```
Then, choose **Microsoft Visual C++ 2019** from the list.

### Compilation

**On Windows, follow these steps to compile the GPU functions:**

1. Set the CUDA path in Matlab (update the path to match your CUDA installation):
    ```matlab
    setenv('MW_NVCC_PATH', 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4\bin');
    ```

2. In the `BEGPUThinning` folder, compile the 3D thinning functions:
    ```matlab
    mexcuda 3D/Matlab3DThinning.cpp 3D/LibThinning3D.cu 3D/ExtractSegments.cpp 3D/CenterlineExtraction.cpp
    ```

3. In the `JermanEnhancementFilter` folder, compile the enhancement filter:
    ```matlab
    mex eig3volume.c
    ```

Make sure you run these commands from the correct folder in Matlab.

# Using this repository for your own project
## Add your config file for your own data path

You should add a json file called `local_config.json` in the root of the repository. 


<b>Note:</b> json files don't support comments, explanation following `//` 
should be considered as comments and removed from your config file

```
{   "datasetPath" : "Add_your_path",   //Folder containing the untreated data
    "savePath" : "Add_your_path", // Folder designated for processed data storage
    "pathConfig2D": "config\\config.json"
}
```
# Running the Code

1. **Create Configuration File**: Ensure that your `local_config.json` file is created and properly configured.
2. **Run Main Script**: Execute `main.m` to save the trajectories of the microbubbles detected using the Tracking and Localization workflow.
3. **Generate ULM Image**: Run `displayDensMap.m` to load the previously generated trajectories and create the ULM image.
4. **Change the parameters of the tracking**

# Modification of Tracking Parameters

You can modify the tracking parameters in `config/config.json` to better suit your data:

1. `sigmas`: This parameter corresponds to the approximate size of your microbubble PSF. The default value is 4, as I am using beamformed data on a grid with a spacing of lambda/4.

2. `tau`: This is the most influential parameter for tracking results. It defines the sensitivity of the tracking algorithm. Lower values (closer to 0) make the algorithm less selective, potentially tracking noise, while higher values (closer to 1) increase selectivity, resulting in fewer trajectories. Adjust this based on how well microbubbles and background are separated in your images.

3. `size_ROI`: You can adjust the size of the ROI (Region of Interest). If you set `debug` to `true` in the `main.m` file during tracking, you will see plots showing the ROIs around microbubble PSFs and the localization positions for some microbubbles.

4. `splineFrequency`: This parameter only affects the display of trajectories. Values closer to 1 will produce smoother trajectories.

# Last Update

The most recent update, addressing an issue, was performed on 13/06/2025.

# Contact

To get in touch with the project maintainer, please reach out to alexis.leconte@polymtl.ca

