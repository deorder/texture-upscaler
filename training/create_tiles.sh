#!/bin/bash
ARGS="${@-./input}"

shopt -s extglob

RATIO_FACTOR=1

INPUT_DIR=${ARGS}
OUTPUT_DIR=./output

MIN_TILE_WIDTH=$((32 * ${RATIO_FACTOR}))
MIN_TILE_HEIGHT=$((32 * ${RATIO_FACTOR}))

MAX_TILE_WIDTH=$((64 * ${RATIO_FACTOR}))
MAX_TILE_HEIGHT=$((64 * ${RATIO_FACTOR}))

mkdir -p "${OUTPUT_DIR}"

find "${INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png"  \) | while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")
  BASENAME=$(basename "${FILENAME%.*}")
  ESCAPED_DIR=$(printf '%q' "${DIRNAME}")
  ESCAPED_FILE=$(printf '%q' "${FILENAME}")
  DIRNAME_HASH=$(echo ${DIRNAME} | md5sum | cut -d' ' -f1)

  COLOR_TYPE=$(identify -format '%[channels]' "${FILENAME}")
  IMAGE_WIDTH=$(identify -format '%[width]' "${FILENAME}")
  IMAGE_HEIGHT=$(identify -format '%[height]' "${FILENAME}")

  RELATIVE_DIR=$(realpath --relative-to "${INPUT_DIR}" "${DIRNAME}")

  if [ "$((${IMAGE_WIDTH}))" -ge "${MIN_TILE_WIDTH}" ] && [ "$((${IMAGE_HEIGHT}))" -ge "${MIN_TILE_HEIGHT}" ]; then

    VERTICAL_SUBDIVISIONS=$((${IMAGE_HEIGHT} / ${MAX_TILE_HEIGHT}))
    if [ "$((${IMAGE_HEIGHT} / ${VERTICAL_SUBDIVISIONS}))" -le "${MIN_TILE_HEIGHT}" ]; then
      VERTICAL_SUBDIVISIONS=$((${IMAGE_HEIGHT} / ${MIN_TILE_HEIGHT}))
    fi
    HORIZONTAL_SUBDIVISIONS=$((${IMAGE_WIDTH} / ${MAX_TILE_WIDTH}))
    if [ "$((${IMAGE_WIDTH} / ${HORIZONTAL_SUBDIVISIONS}))" -le "${MIN_TILE_WIDTH}" ]; then
      HORIZONTAL_SUBDIVISIONS=$((${IMAGE_WIDTH} / ${MIN_TILE_WIDTH}))
    fi

    if [ "$(convert "${FILENAME}" -alpha off -format "%[k]" info:)" -gt "1" ]; then
      echo ${FILENAME}, rgb \(${IMAGE_WIDTH}x${IMAGE_HEIGHT} divided by ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}\)
      convert "${FILENAME}" -alpha off -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME}_%03d.png"
    else
      echo ${FILENAME}, rgb single color, skipped
    fi
    if [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
      if [ "$(convert "${FILENAME}" -alpha extract -format "%[k]" info:)" -gt "1" ]; then
        echo ${FILENAME}, alpha \(${IMAGE_WIDTH}x${IMAGE_HEIGHT} divided by ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}\)
        convert "${FILENAME}" -alpha extract -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME}_alpha_%03d.png"
      else
        echo ${FILENAME}, alpha single color, skipped
      fi
    fi

  else
    echo ${FILENAME} too small \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), skipped
  fi
  
done
