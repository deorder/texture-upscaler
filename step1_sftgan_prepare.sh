#!/bin/bash
ARGS="${@-./input}"

:> index.txt
shopt -s extglob

RESIZE=2
OVERDRAW=16
TILE_COUNT=16

FILTER=point
INTERPOLATE=Nearest

INPUT_DIR=${ARGS}
SFTGAN_DIR=./sftgan

TILE_PER_ROW=$(echo "${TILE_COUNT}" | awk '{print sqrt($1)}')
TILE_PER_COLUMN=$(echo "${TILE_COUNT}" | awk '{print sqrt($1)}')

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

  echo ${FILENAME}

  NEW_IMAGE_WIDTH=$((${IMAGE_WIDTH} * ${RESIZE}))
  NEW_IMAGE_HEIGHT=$((${IMAGE_HEIGHT} * ${RESIZE}))
  TILE_WIDTH=$((${NEW_IMAGE_WIDTH} / ${TILE_PER_COLUMN}))
  TILE_HEIGHT=$((${NEW_IMAGE_HEIGHT} / ${TILE_PER_ROW}))

  if [ "${COLOR_TYPE}" == "rgb" ] || [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgb" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
    for TILE_ROW_INDEX in $(seq 0 $((${TILE_PER_ROW} - 1))); do
      for TILE_COLUMN_INDEX in $(seq 0 $((${TILE_PER_COLUMN} - 1))); do

        TILE_INDEX=$(((${TILE_ROW_INDEX} * ${TILE_PER_ROW}) + ${TILE_COLUMN_INDEX}))
        TILE_X1=$((${TILE_COLUMN_INDEX} * ${TILE_WIDTH}))
        TILE_Y1=$((${TILE_ROW_INDEX} * ${TILE_HEIGHT}))
        TILE_X2=$(((${TILE_COLUMN_INDEX} * ${TILE_WIDTH}) + ${TILE_WIDTH}))
        TILE_Y2=$(((${TILE_ROW_INDEX} * ${TILE_HEIGHT}) + ${TILE_HEIGHT}))

        convert "${FILENAME}" -interpolate ${INTERPOLATE} -filter ${FILTER} -alpha off -resize ${NEW_IMAGE_WIDTH}x${NEW_IMAGE_HEIGHT} -crop $((${TILE_WIDTH} + ${OVERDRAW}))x$((${TILE_HEIGHT} + ${OVERDRAW}))+${TILE_X1}+${TILE_Y1} +repage +adjoin -define png:color-type=2 "${SFTGAN_DIR}/data/samples/${DIRNAME_HASH}_${BASENAME}_${TILE_INDEX}.png"

        if [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
          convert "${FILENAME}" -interpolate ${INTERPOLATE} -filter ${FILTER} -alpha extract -resize ${NEW_IMAGE_WIDTH}x${NEW_IMAGE_HEIGHT} -crop $((${TILE_WIDTH} + ${OVERDRAW}))x$((${TILE_HEIGHT} + ${OVERDRAW}))+${TILE_X1}+${TILE_Y1} +repage +adjoin -define png:color-type=2 "${SFTGAN_DIR}/data/samples/${DIRNAME_HASH}_${BASENAME}_alpha_${TILE_INDEX}.png"
        fi

      done
    done

    if [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
      echo "${DIRNAME_HASH}:${BASENAME}:${RELATIVE_DIR}:rgba:${IMAGE_WIDTH}:${IMAGE_HEIGHT}:${TILE_PER_ROW}:${TILE_PER_COLUMN}" >> index.txt
    elif [ "${COLOR_TYPE}" == "rgb" ] || [ "${COLOR_TYPE}" == "srgb" ]; then
      echo "${DIRNAME_HASH}:${BASENAME}:${RELATIVE_DIR}:rgb:${IMAGE_WIDTH}:${IMAGE_HEIGHT}:${TILE_PER_ROW}:${TILE_PER_COLUMN}" >> index.txt
    fi
  else
    echo "${FILENAME} is ${COLOR_TYPE}, skipping"
  fi
  
done
