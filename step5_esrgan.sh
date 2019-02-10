#!/bin/bash

ESRGAN_DIR=./esrgan

pushd ${ESRGAN_DIR}/
python3 test.py ./models/RRDB_ESRGAN_x4.pth
popd
