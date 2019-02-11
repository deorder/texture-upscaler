# Cathedral Project texture upscaler using ESRGAN and SFTGAN

## Installation

 - Install ESRGAN to `./esrgan`
 
 - Follow the instructions for installing ESRGAN at: https://github.com/xinntao/ESRGAN

 - Install SFTGAN to `./sftgan`

 - Follow the instructions for installing SFTGAN at: https://github.com/xinntao/SFTGAN

## Usage

 - Put all the textures you want to process inside the `./input` directory

 - Run all steps (some may take a long time to complete, also check out the settings at the top of the `.sh` files)

   - *step 1:* separating RGB and alpha, upscaling by 200%, cutting the image in 16 tiles + 16px overlap
   - *step 2:* running the semantic segmentation on all the tiles
   - *step 3:* running SFTGAN on all tiles, they will have the same dimensions as the input files but with more details added
   - *step 4:* preparing the result from SFTGAN to be processed by ESRGAN
   - *step 5:* running ESRGAN on all tiles upscaling them by 400%
   - *step 6:* combining all tiles (also recombining the RGB and alpha channels where needed) using the overlap for blending to prevent seams

 - The results will be stored inside the `./output` directory

 **Note:** Try out different combinations. All shell scripts have options that you can change at the top
 
 **Note:** Upscaling the textures before running SFT may give better results
 
 **Note:** You may want to upscale normal maps using ESRGAN only. Do not forget to renormalize them.
 
 **Note:** If you change the overlap in step 1, change the overlap in step 6 accordingly
 
## Troubleshooting

- You may have to increase some of the values in Image Magick's `policy.xml` file to allow for more memory to be used.
- If Image Magick keeps complaining about memory limits you can comment out the `resource` lines in `policy.xml`

## Requirements
 - Bash (if you do not have Linux you can try the Git for Window's Bash instead)
 - Image Magick
 - ESRGAN: https://github.com/xinntao/ESRGAN
 - SFTGAN: https://github.com/xinntao/SFTGAN
 - Python 3 64-bit
 - PyTorch
 - Cuda (optional, but recommended if you have an NVidia)
