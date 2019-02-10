#!/bin/bash
ARGS="${@}"

shopt -s extglob

RESIZE=100%
TILE_COUNT=16

SFTGAN_DIR=./sftgan
ESRGAN_DIR=./esrgan

cat index.txt | while read ENTRY; do
  DIRNAME=$(echo ${ENTRY} | cut -d':' -f3)
  BASENAME=$(echo ${ENTRY} | cut -d':' -f2)
  COLOR_TYPE=$(echo ${ENTRY} | cut -d':' -f4)
  DIRNAME_HASH=$(echo ${ENTRY} | cut -d':' -f1)

  echo ${BASENAME} ${DIRNAME} ${COLOR_TYPE} ${DIRNAME_HASH}

  for TILE_INDEX in $(seq 0 $((${TILE_COUNT} - 1))); do
    convert "${SFTGAN_DIR}/data/samples_result/${DIRNAME_HASH}_${BASENAME}_${TILE_INDEX}_rlt.png" -resize ${RESIZE} "${ESRGAN_DIR}/LR/${DIRNAME_HASH}_${BASENAME}_${TILE_INDEX}.png"
    if [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
      convert "${SFTGAN_DIR}/data/samples_result/${DIRNAME_HASH}_${BASENAME}_alpha_${TILE_INDEX}_rlt.png" -resize ${RESIZE} "${ESRGAN_DIR}/LR/${DIRNAME_HASH}_${BASENAME}_alpha_${TILE_INDEX}.png"
    fi
  done
done
