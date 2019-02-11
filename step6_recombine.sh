#!/bin/bash
ARGS="${@-./output}"

shopt -s extglob

RESIZE=50%
OVERDRAW=64

OUTPUT_DIR=${ARGS}
ESRGAN_DIR=./esrgan

cat index.txt | while read ENTRY; do
  DIRNAME=$(echo ${ENTRY} | cut -d':' -f3)
  BASENAME=$(echo ${ENTRY} | cut -d':' -f2)
  COLOR_TYPE=$(echo ${ENTRY} | cut -d':' -f4)
  DIRNAME_HASH=$(echo ${ENTRY} | cut -d':' -f1)
  
  IMAGE_WIDTH=$(echo ${ENTRY} | cut -d':' -f5)
  IMAGE_HEIGHT=$(echo ${ENTRY} | cut -d':' -f6)
  
  TILE_PER_ROW=$(echo ${ENTRY} | cut -d':' -f7)
  TILE_PER_COLUMN=$(echo ${ENTRY} | cut -d':' -f8)
  
  TILE_WIDTH=$(identify -format '%[width]' "${ESRGAN_DIR}/results/${DIRNAME_HASH}_${BASENAME}_0_rlt.png")
  TILE_HEIGHT=$(identify -format '%[height]' "${ESRGAN_DIR}/results/${DIRNAME_HASH}_${BASENAME}_0_rlt.png")

  echo ${BASENAME} ${DIRNAME} ${COLOR_TYPE} ${DIRNAME_HASH}

  mkdir -p "${OUTPUT_DIR}/${DIRNAME}"

  COMPOSITE_ARGS=""
  ALPHA_COMPOSITE_ARGS=""
  for TILE_ROW_INDEX in $(seq $((${TILE_PER_ROW} - 1)) -1 0); do
    for TILE_COLUMN_INDEX in $(seq $((${TILE_PER_COLUMN} - 1)) -1 0); do

      TILE_INDEX=$(((${TILE_ROW_INDEX} * ${TILE_PER_ROW}) + ${TILE_COLUMN_INDEX}))
      TILE_X1=$((${TILE_COLUMN_INDEX} * (${TILE_WIDTH} - ${OVERDRAW})))
      TILE_Y1=$((${TILE_ROW_INDEX} * (${TILE_HEIGHT} - ${OVERDRAW})))
      TILE_X2=$((${TILE_X1} + ${TILE_WIDTH}))
      TILE_Y2=$((${TILE_Y1} + ${TILE_HEIGHT}))

      INPUT_FILENAME="${ESRGAN_DIR}/results/${DIRNAME_HASH}_${BASENAME}_${TILE_INDEX}_rlt.png"
      ALPHA_INPUT_FILENAME="${ESRGAN_DIR}/results/${DIRNAME_HASH}_${BASENAME}_alpha_${TILE_INDEX}_rlt.png"

      COMPOSITE_ARGS="${COMPOSITE_ARGS} \\( \"${INPUT_FILENAME}\" -clone 0 -compose CopyOpacity +matte -composite -repage +${TILE_X1}+${TILE_Y1} \\)"
      ALPHA_COMPOSITE_ARGS="${ALPHA_COMPOSITE_ARGS} \\( \"${ALPHA_INPUT_FILENAME}\" -clone 0 -compose CopyOpacity +matte -composite -repage +${TILE_X1}+${TILE_Y1} \\)"

    done
  done

  BLEND_ARGS="\\( -size ${TILE_WIDTH}x${TILE_HEIGHT} xc:white \\( -size ${TILE_HEIGHT}x${OVERDRAW} gradient: -append -rotate 90 \\) -composite -compose multiply \\( -size ${TILE_WIDTH}x${OVERDRAW} gradient: -append -rotate 180 \\) -composite -rotate 180 \\)"

  ALPHA_ARGS="${BLEND_ARGS} ${ALPHA_COMPOSITE_ARGS} -delete 0 -compose Over -mosaic"
  RGB_ARGS="${BLEND_ARGS} ${COMPOSITE_ARGS} -delete 0 -compose Over -mosaic"

  if [ "${COLOR_TYPE}" == "rgba" ] || [ "${COLOR_TYPE}" == "srgba" ]; then
    COMMAND="convert \\( ${RGB_ARGS} -resize ${RESIZE} \\) \\( ${ALPHA_ARGS} -colorspace gray -alpha off -resize ${RESIZE} \\) -compose copy-opacity -composite \"${OUTPUT_DIR}/${DIRNAME}/${BASENAME}.png\""
  fi

  if [ "${COLOR_TYPE}" == "rgb" ] || [ "${COLOR_TYPE}" == "srgb" ]; then
    COMMAND="convert \\( ${RGB_ARGS} \\) -resize ${RESIZE} \"${OUTPUT_DIR}/${DIRNAME}/${BASENAME}.png\""
  fi

  sh -c "${COMMAND}"
  #echo "${COMMAND}"
done
