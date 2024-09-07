# TrackingAndLocalizationULM
This is the joint repository for the paper : [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (IEEE TMI:10.1109/TMI.2024.3456676 )](https://arxiv.org/abs/2308.02724)

## If you use the code, please cite the corresponding papers:

- [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (arXiv:2308.02724)](https://arxiv.org/abs/2308.02724)
- [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)
- [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)

## RELATED DATASET:

In vivo mouse brain dataset is available at https://doi.org/10.20383/103.01058.


# Installation 

## Cloning the repository
 This repository contains submodules so use : 

`git clone --recurse-submodules git@github.com:provostultrasoundlab/TrackingAndLocalizationULM.git`

Here is the list of the different submodules : 
- BEGPUThinning.git : [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)
- JermanEnhancementFilter.git : [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)
## Compilation GPU functions 
(On Windows) Run in your matlab :
* `setenv('MW_NVCC_PATH', 'C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4\bin');` change the path with your version of CUDA
* In the folder `BEGPUThinning` run the command `mexcuda 3D/Matlab3DThinning.cpp 3D/LibThinning3D.cu 3D/ExtractSegments.cpp 3D/CenterlineExtraction.cpp` 
* In the folder `JermanEnhancementFilter` run the command `mex eig3volume.c`

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


# Contact

To get in touch with the project maintainer, please reach out to alexis.leconte@polymtl.ca

