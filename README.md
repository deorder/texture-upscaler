# Shell scripts to prepare textures for ESR/SFTGAN etc.

Table of Contents
=================

  * [Description](#description)
     * [Scripts to prepare for inference](#scripts-to-prepare-for-inference)
     * [Scripts to prepare for training](#scripts-to-prepare-for-training)
  * [Installing ESRGAN and/or SFTGAN](#installing-esrgan-andor-sftgan)
     * [If you want to use ESRGAN to upscale](#if-you-want-to-use-esrgan-to-upscale)
     * [If you want to use SFTGAN to upscale](#if-you-want-to-use-sftgan-to-upscale)
     * [If you want to train SFTGAN and/or SFTGAN](#if-you-want-to-train-sftgan-andor-sftgan)
  * [Usage for inference/upscaling with ESRGAN and/or SFTGAN](#usage-for-inferenceupscaling-with-esrgan-andor-sftgan)
     * [Steps when you want to use ESRGAN only](#steps-when-you-want-to-use-esrgan-only)
     * [Steps when you want to use SFTGAN only](#steps-when-you-want-to-use-sftgan-only)
     * [Steps when you want to use ESRGAN and then SFTGAN](#steps-when-you-want-to-use-esrgan-and-then-sftgan)
     * [Steps when you want to use SFTGAN and then ESRGAN](#steps-when-you-want-to-use-sftgan-and-then-esrgan)
  * [Usage for training ESRGAN and/or SFTGAN](#usage-for-training-esrgan-andor-sftgan)
  * [Troubleshooting](#troubleshooting)
  * [Requirements](#requirements)
     * [Required if you want to use ESRGAN and/or SFTGAN](#required-if-you-want-to-use-esrgan-andor-sftgan)
     * [Required if you want to train ESRGAN](#required-if-you-want-to-train-esrgan)


## Description

The included scripts are for preparing your images to be used by ESRGAN, SFTGAN etc. and ressassemble them (no seams)

**Note:** Will only work on power of 2 sized textures at the moment

### Scripts to prepare for inference ###
`step1_create_tiles.sh`: Create tiles with overlap, separating the RGB and alpha, with optional rescaling

`step2_copy_tiles.sh`: Copy tiles from one directory to the next, with optional rescaling while copying

`step3_assemble_tiles.sh`: Reassemble tiles and use the overlap for blending (to remove seams), recombine the RGB and alpha, with optional rescaling

### Scripts to prepare for training  ###
`training/step1_create_tiles.sh`: Create equal size tiles (1 for HR/GT, 1 downscaled for LR), separating the RGB and alpha, use separate directories according to regexp

`training/step2_cleanup_tiles.sh`: Cleanup tiles, remove tiles that have too little colors and/or that do not fit the required size for HR/GT and LR

`training/step3_select_tiles.sh`: Select tiles according to a specified percentage to be used for training and validation

## Installing ESRGAN and/or SFTGAN

### If you want to use ESRGAN to upscale

 - Install ESRGAN to `./esrgan`
 - Follow the instructions for installing ESRGAN at: https://github.com/xinntao/ESRGAN

### If you want to use SFTGAN to upscale

 - Install SFTGAN to `./sftgan`
 - Follow the instructions for installing SFTGAN at: https://github.com/xinntao/SFTGAN

### If you want to train SFTGAN and/or SFTGAN

 - Install BasicSR to `./basicsr`
 - Follow the instructions for installing BasicSR at: https://github.com/xinntao/BasicSR

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
  - `pushd ./sftgan/pytorch_test/; python3 test_segmentation.py; popd`
  - `pushd ./sftgan/pytorch_test/; python3 test_sftgan.py; popd`
  - `./step3_assemble_tiles.sh --input-dir="./sftgan/data/samples_result" --input-postfix="_rlt"`
  - Results will be inside `./output`

### Steps when you want to use SFTGAN and then ESRGAN

  - Put all the textures you want to process inside the `./input` directory
  - `./step1_create_tiles.sh --output-dir="./sftgan/data/samples" --rescale="200%"` (SFTGAN requires you to upscale first)
  - `pushd ./sftgan/pytorch_test/; python3 test_segmentation.py; popd`
  - `pushd ./sftgan/pytorch_test/; python3 test_sftgan.py; popd`
  - `./step2_copy_tiles.sh --input-dir="./sftgan/data/samples_result" --output-dir="./esrgan/LR" --input-postfix="_rlt"`
  - `pushd ./esrgan/; python3 test.py ./models/RRDB_ESRGAN_x4.pth; popd` (Replace model path if you want)
  - `./step3_assemble_tiles.sh --input-dir="./esrgan/results" --input-postfix="_rlt"`
  - Results will be inside `./output`

 **Note:** Try out different combinations of settings, use `./<script>.sh --help`
 
 **Note:** Upscaling the textures before running SFT may give better results
 
 **Note:** Everything works much better on Linux

## Usage for training ESRGAN and/or SFTGAN

 - Put all textures you want to use for training in `./training/input`
 - Go to the `./training` directory
 - `./step1_create_tiles.sh`
 - Results will be inside `./training/output`
 - `./step2_cleanup_tiles.sh`
 - `./step3_select_tiles.sh`
 - End result will be inside `./training/output_training` and `./training/output_validation`
 - Go to `<basicsr path>/codes` and modify the `options/train/train_ESRGAN.json` file as follows:
   - Change the `name` to something else that has no `debug` in it.
   - In `train` you may want to decrease the `n_workers` and `batch_size` values to for ex.: 4 and 8
   - In `train` point the `dataroot_LR` to `<path>/training/output_training/LR`
   - In `train` point the `dataroot_HR` to `<path>/training/output_training/HR`
   - In `val` point the `dataroot_LR` to `<path>/training/output_validation/LR`
   - In `val` point the `dataroot_HR` to `<path>/training/output_validation/HR`
   - In `path` change `root` to the folder where BasicSR is installed
   - In `path` you may have to remove `resume_state` for now
 - In `<basicsr path>/codes` run the following: `python3 train.py -opt options/train/train_ESRGAN.json`
 - Results will be inside `<basicsr path>/experiments`, after every X iterations it will write some validation results
 - If you are happy with the validation results you can stop the training using Ctrl+C
 - If you want to continue training make sure that in `train_ESRGAN.json` the `resume_state` is set in `path` pointing to the state file `<basicsr path>/experiments/<name>/training_state/<state file>.state` you want to continue training from
 
## Troubleshooting

- You may have to increase some of the values in Image Magick's `policy.xml` file to allow for more memory to be used.
- If Image Magick keeps complaining about memory limits you can comment out the `resource` lines in `policy.xml`

## Requirements
 - Bash (if you do not have Linux you can try the Git for Window's Bash instead)
 - Image Magick

### Required if you want to use ESRGAN and/or SFTGAN
 - Cuda (optional, but recommended if you have an NVidia) (On Linux you can just install the latest NVidia drivers)
 - ESRGAN: https://github.com/xinntao/ESRGAN
 - SFTGAN: https://github.com/xinntao/SFTGAN
 - Python 3 64-bit
 - PyTorch
 
### Required if you want to train ESRGAN
 - Python modules: numpy opencv-python torchvision tensorboardX lmdb
 - BasicSR: https://github.com/xinntao/BasicSR/

