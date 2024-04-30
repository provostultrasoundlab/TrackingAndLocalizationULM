# Article_Alexis
This is the joint repository for the paper : [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (arXiv:2308.02724)](https://arxiv.org/abs/2308.02724)

If you use the code, please cite the corresponding papers:

- [A. Leconte, J. Porée, B. Rauby, A. Wu, N. Ghigo, P. Xing, C. Bourquin, G. Ramos-Palacios, A. F. Sadikot, J. Provost,  "*A Tracking prior to Localization workflow for Ultrasound Localization Microscopy*", (arXiv:2308.02724)](https://arxiv.org/abs/2308.02724)
- [B. Heiles, A. Chavignon, V. Hingot, P. Lopez, E. Teston, O. Couture*Performance benchmarking of microbubble-localization algorithms for ultrasound localization microscopy*, Nature Biomedical Engineering, 2022 (10.1038/s41551-021-00824-8)](https://www.nature.com/articles/s41551-021-00824-8)
- [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)
- [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)
# Installation 

## Cloning the repository
 This repository contains submodules so use : 

`git clone --recurse-submodules git@github.com:provostultrasoundlab/TrackingAndLocalizationULM.git`

Here is the list of the different submodules : 
- BEGPUThinning.git : [M. G. Wagner, "*Real-Time Thinning Algorithms for 2D and 3D Images using GPU processors*", J Real-Time Image Proc (2019), (10.1007/s11554-019-00886-7)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7962620/)
- JermanEnhancementFilter.git : [T. Jerman, F. Pernus, B. Likar, Z. Spiclin, "*Enhancement of Vascular Structures in 3D and 2D Angiographic Images*", IEEE Transactions on Medical Imaging, 35(9), p. 2107-2118 (2016), (10.1109/TMI.2016.2550102)](https://doi.org/10.1109/TMI.2016.2550102)
- PALA.git : [B. Heiles, A. Chavignon, V. Hingot, P. Lopez, E. Teston, O. Couture*Performance benchmarking of microbubble-localization algorithms for ultrasound localization microscopy*, Nature Biomedical Engineering, 2022 (10.1038/s41551-021-00824-8)](https://www.nature.com/articles/s41551-021-00824-8)
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
{   "datasetName2D" : "Add_your_path",   //Subfolder containing the untreated data
    "dataPrefix2D" : "Add_your_path", // Folder containing the subfolder which contains the untreated data
    "savePrefix2D" : "Add_your_path", // Folder where the subfolder containing the treated data will be saved
    "pathConfig2D": "config\config.json"
}

```
## Modify main.m as follows:
 - To use this repository, you will need to load your IQ data post SVD (depth $\times$ lateral axis $\times$ time ) : l.23 in `main.m`
- you must fill in the variable: frameRate l.26 in `main.m`

# PALA Dataset

In the folder `example`, we provide `PALA_TAL_InVivoULM_example.m`  a script adapted from `PALA_InVivoULM_example.m`. 

This script can process the dataset :  `PALA_data_InVivoRatBrain`. You can download the dataset with thoses links:
- [PALA_data_InVivoRatBrain_part1](https://zenodo.org/records/4343435/files/PALA_data_InVivoRatBrain_part1.zip?download=1)  
- [PALA_data_InVivoRatBrain_part2](https://zenodo.org/records/4343435/files/PALA_data_InVivoRatBrain_part2.zip?download=1)

You should add a json file called `local_config.json` in the root of the repository. 


<b>Note:</b> json files don't support comments, explanation following `//` 
should be considered as comments and removed from your config file

```
{   
    "pathConfig2D": "config\config.json"
}
```
# Contact

To get in touch with the project maintainer, please reach out to alexis.leconte@polymtl.ca

