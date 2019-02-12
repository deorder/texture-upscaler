# Cathedral Project texture scripts to prepare for ESRGAN, SFTGAN or others

## Description

The included scripts are for preparing your images to be used by ESRGAN, SFTGAN or others

### Description of steps to prepare for inference ###
`step1_create_tiles.sh`: Create tiles with overlap, separating the RGB and alpha, with optional rescaling

`step2_copy_tiles.sh`: Copy tiles from one directory to the next, with optional rescaling while copying

`step3_assemble_tiles.sh`: Reassemble tiles and use the overlap for blending (to remove seams), recombine the RGB and alpha, with optional rescaling

### Description of steps to prepare for training  ###
`training/step1_create_tiles.sh`: Create equal size tiles (1 for HR/GT, 1 downscaled for LR), separating the RGB and alpha, use separate directories according to regexp

`training/step2_cleanup_tiles.sh`: Cleanup tiles, remove tiles that have too little colors and/or that do not fit the required size for HR/GT and LR

## Installation for use with ESRGAN and/or SFTGAN

### If you want to use ESRGAN

 - Install ESRGAN to `./esrgan`
 - Follow the instructions for installing ESRGAN at: https://github.com/xinntao/ESRGAN

### If you want to use SFTGAN

 - Install SFTGAN to `./sftgan`
 - Follow the instructions for installing SFTGAN at: https://github.com/xinntao/SFTGAN

## Usage for inference/upscaling with ESRGAN and/or SFTGAN

### Steps when you want to use ESRGAN only

  - Put all the textures you want to process inside the `./input` directory
  - `./step1_create_tiles.sh --output-dir="./esrgan/LR"`
  - `pushd ./esrgan/; python3 test.py ./models/RRDB_ESRGAN_x4.pth; popd` (Replace model path if you want)
  - `./step3_assemble_tiles.sh --input-dir="./esrgan/results" --input-postfix="_rlt"`
  - Results will be inside `./output`

### Steps when you want to use SFTGAN only

  - Put all the textures you want to process inside the `./input` directory
  - `./step1_create_tiles.sh --output-dir="sftgan/data/samples" --rescale="200%"` (SFTGAN requires you to upscale first)
  - `pushd ./sftgan/pytorch_test/; python3 test_sftgan.py; popd`
  - `./step3_assemble_tiles.sh --input-dir="./sftgan/data/samples_result" --input-postfix="_rlt"`
  - Results will be inside `./output`

### Steps when you want to use ESRGAN and then SFTGAN

  - Put all the textures you want to process inside the `./input` directory
  - `./step1_create_tiles.sh --output-dir="./esrgan/LR"`
  - `pushd ./esrgan/; python3 test.py ./models/RRDB_ESRGAN_x4.pth; popd` (Replace model path if you want)
  - `./step2_copy_tiles.sh --input-dir="./esrgan/results" --output-dir"./sftgan/data/samples" --input-postfix="_rlt"`
  - `pushd ./sftgan/pytorch_test/; python3 test_sftgan.py; popd`
  - `./step3_assemble_tiles.sh --input-dir="./sftgan/data/samples_result" --input-postfix="_rlt"`
  - Results will be inside `./output`

### Steps when you want to use SFTGAN and then ESRGAN

  - Put all the textures you want to process inside the `./input` directory
  - `./step1_create_tiles.sh --output-dir="./sftgan/data/samples" --rescale="200%"` (SFTGAN requires you to upscale first)
  - `pushd ./sftgan/pytorch_test/; python3 test_sftgan.py; popd`
  - `./step2_copy_tiles.sh --input-dir="./sftgan/data/samples_result" --output-dir="./esrgan/LR" --input-postfix="_rlt"`
  - `pushd ./esrgan/; python3 test.py ./models/RRDB_ESRGAN_x4.pth; popd` (Replace model path if you want)
  - `./step3_assemble_tiles.sh --input-dir="./esrgan/results" --input-postfix="_rlt"`
  - Results will be inside `./output`

 **Note:** Try out different combinations. All shell scripts have options that you can change at the top
 
 **Note:** Upscaling the textures before running SFT may give better results
 
 **Note:** You may want to upscale normal maps using ESRGAN only. Do not forget to renormalize them.
 
 **Note:** If you change the overlap in step 1, change the overlap in step 6 accordingly

 **Note:** Everything works much better on Linux

## Usage to prepare for training (WiP)

 - Put all textures you want to use for training in `./training/input`
 - Go to the `./training` directory
 - `./step1_create_tiles.sh`
 - `./step2_cleanup_tiles.sh`
 - Results will be inside `./training/output`
 
## Troubleshooting

- You may have to increase some of the values in Image Magick's `policy.xml` file to allow for more memory to be used.
- If Image Magick keeps complaining about memory limits you can comment out the `resource` lines in `policy.xml`

## Requirements
 - Cuda (optional, but recommended if you have an NVidia) (On Linux you can just install the latest NVidia drivers)
 - Bash (if you do not have Linux you can try the Git for Window's Bash instead)
 - ESRGAN: https://github.com/xinntao/ESRGAN
 - SFTGAN: https://github.com/xinntao/SFTGAN
 - Python 3 64-bit
 - Image Magick
 - PyTorch
