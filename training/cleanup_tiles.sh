#!/bin/bash
ARGS="${@-./output}"

shopt -s extglob

OUTPUT_DIR=${ARGS}

# Min colors treshold
MIN_COLORS=8

# Min and max must be equal
LR_MIN_TILE_WIDTH=32
LR_MIN_TILE_HEIGHT=32

LR_MAX_TILE_WIDTH=32
LR_MAX_TILE_HEIGHT=32

HR_MIN_TILE_WIDTH=128
HR_MIN_TILE_HEIGHT=128

HR_MAX_TILE_WIDTH=128
HR_MAX_TILE_HEIGHT=128

# Examples
LR_OUTPUT_DIR=${OUTPUT_DIR}/LR

# Ground truth
HR_OUTPUT_DIR=${OUTPUT_DIR}/HR

find "${HR_OUTPUT_DIR}" \( -iname "*.dds" -or -iname "*.png"  \) | while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  IMAGE_INFO=$(identify -format '%[width] %[height] %[channels] %[k]' "${FILENAME}")
  IMAGE_WIDTH=$(echo ${IMAGE_INFO} | cut -d' ' -f 1)
  IMAGE_HEIGHT=$(echo ${IMAGE_INFO} | cut -d' ' -f 2)
  IMAGE_COLORS=$(echo ${IMAGE_INFO} | cut -d' ' -f 4)
  IMAGE_CHANNELS=$(echo ${IMAGE_INFO} | cut -d' ' -f 3)
  
  RELATIVE_DIR=$(realpath --relative-to "${HR_OUTPUT_DIR}" "${DIRNAME}")

  echo ${RELATIVE_DIR}/${BASENAME_NO_EXT} \(${IMAGE_WIDTH} ${IMAGE_HEIGHT} ${IMAGE_CHANNELS} ${IMAGE_COLORS}\)

  if [ "${IMAGE_COLORS}" -le "${MIN_COLORS}" ]; then
    echo ${RELATIVE_DIR}, too little colors \(${MIN_COLORS}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    continue
  fi
  
  if [ "${IMAGE_CHANNELS}" != "rgb" ] && [ "${IMAGE_CHANNELS}" != "srgb" ]; then
    echo ${RELATIVE_DIR}, not rgb \(${IMAGE_CHANNELS}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    continue
  fi

  if [ "${IMAGE_WIDTH}" -lt "${HR_MIN_TILE_WIDTH}" ] || [ "${IMAGE_HEIGHT}" -lt "${HR_MIN_TILE_HEIGHT}" ]; then
    echo ${RELATIVE_DIR}, too small \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    continue
  fi

  if [ "${IMAGE_WIDTH}" -gt "${HR_MAX_TILE_WIDTH}" ] || [ "${IMAGE_HEIGHT}" -gt "${HR_MAX_TILE_HEIGHT}" ]; then
    echo ${RELATIVE_DIR}, too big \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), delete
    rm -f ${HR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    rm -f ${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}
    continue
  fi
  
done
