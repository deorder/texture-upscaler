#!/bin/bash
ARGS="${@-./input}"

shopt -s extglob

INPUT_DIR=${ARGS}

# Examples
LR_SCALE=25%
LR_FILTER=point
LR_INTERPOLATE=Nearest
LR_OUTPUT_DIR=./output/LR

# Ground truth
HR_SCALE=100%
HR_FILTER=point
HR_INTERPOLATE=Nearest
HR_OUTPUT_DIR=./output/HR

# Min and max must be equal
MIN_TILE_WIDTH=128
MIN_TILE_HEIGHT=128

MAX_TILE_WIDTH=128
MAX_TILE_HEIGHT=128

# Category regexp for Skyrim SE
CATEGORY_REGEXP='s/.*_\(a\|b\|d\|e\|g\|h\|m\|n\|p\|s\|an\|bl\|em\|sk\|msn\|rim\)$/\1/ip'

wait_for_jobs() {
  local JOBLIST=($(jobs -p))
  if [ "${#JOBLIST[@]}" -gt "4" ]; then
    for JOB in ${JOBLIST}; do
      echo Waiting for job ${JOB}...
      wait ${JOB}
    done
  fi
}

find "${INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png"  \) | while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  ESCAPED_DIR=$(printf '%q' "${DIRNAME}")
  ESCAPED_FILE=$(printf '%q' "${FILENAME}")

  DIRNAME_HASH=$(echo ${DIRNAME} | md5sum | cut -d' ' -f1)

  CATEGORY=$(echo ${BASENAME} | sed -ne "${CATEGORY_REGEXP}")

  if [ ! -f "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_000.png" ]; then

    IMAGE_INFO=$(identify -format '%[width] %[height] %[channels]' "${FILENAME}")
    IMAGE_WIDTH=$(echo ${IMAGE_INFO} | cut -d' ' -f 1)
    IMAGE_HEIGHT=$(echo ${IMAGE_INFO} | cut -d' ' -f 2)
    IMAGE_CHANNELS=$(echo ${IMAGE_INFO} | cut -d' ' -f 3)

    RELATIVE_DIR=$(realpath --relative-to "${INPUT_DIR}" "${DIRNAME}")

    if [ "${IMAGE_WIDTH}" -ge "${MIN_TILE_WIDTH}" ] && [ "${IMAGE_HEIGHT}" -ge "${MIN_TILE_HEIGHT}" ]; then

      VERTICAL_SUBDIVISIONS=$((${IMAGE_HEIGHT} / ${MAX_TILE_HEIGHT}))
      if [ "${VERTICAL_SUBDIVISIONS}" -lt "1" ]; then
        VERTICAL_SUBDIVISIONS=$((${IMAGE_HEIGHT} / ${MIN_TILE_HEIGHT}))
      fi
      HORIZONTAL_SUBDIVISIONS=$((${IMAGE_WIDTH} / ${MAX_TILE_WIDTH}))
      if [ "${HORIZONTAL_SUBDIVISIONS}" -lt "1" ]; then
        HORIZONTAL_SUBDIVISIONS=$((${IMAGE_WIDTH} / ${MIN_TILE_WIDTH}))
      fi

      if [ "$(convert "${FILENAME}" -alpha off -format "%[k]" info:)" -gt "1" ]; then
        mkdir -p "${HR_OUTPUT_DIR}/${CATEGORY}/rgb"
        mkdir -p "${LR_OUTPUT_DIR}/${CATEGORY}/rgb"
        echo ${FILENAME}, rgb \(${IMAGE_WIDTH}x${IMAGE_HEIGHT} divided by ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}\) ${CATEGORY}
        wait_for_jobs
        convert "${FILENAME}" -alpha off -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 -interpolate ${HR_INTERPOLATE} -filter ${HR_FILTER} -resize ${HR_SCALE} "${HR_OUTPUT_DIR}/${CATEGORY}/rgb/${DIRNAME_HASH}_${BASENAME_NO_EXT}_%03d.png" &
        wait_for_jobs
        convert "${FILENAME}" -alpha off -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 -interpolate ${LR_INTERPOLATE} -filter ${LR_FILTER} -resize ${LR_SCALE} "${LR_OUTPUT_DIR}/${CATEGORY}/rgb/${DIRNAME_HASH}_${BASENAME_NO_EXT}_%03d.png" &
      else
        echo ${FILENAME}, rgb single color, skipped
      fi
      if [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
        if [ "$(convert "${FILENAME}" -alpha extract -format "%[k]" info:)" -gt "1" ]; then
          mkdir -p "${HR_OUTPUT_DIR}/${CATEGORY}/alpha"
          mkdir -p "${LR_OUTPUT_DIR}/${CATEGORY}/alpha"
          echo ${FILENAME}, alpha \(${IMAGE_WIDTH}x${IMAGE_HEIGHT} divided by ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}\) ${CATEGORY}
          wait_for_jobs
          convert "${FILENAME}" -alpha extract -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 -interpolate ${HR_INTERPOLATE} -filter ${HR_FILTER} -resize ${HR_SCALE} "${HR_OUTPUT_DIR}/${CATEGORY}/alpha/${DIRNAME_HASH}_${BASENAME_NO_EXT}_alpha_%03d.png" &
          wait_for_jobs
          convert "${FILENAME}" -alpha extract -crop ${HORIZONTAL_SUBDIVISIONS}x${VERTICAL_SUBDIVISIONS}@ +repage +adjoin -define png:color-type=2 -interpolate ${LR_INTERPOLATE} -filter ${LR_FILTER} -resize ${LR_SCALE} "${LR_OUTPUT_DIR}/${CATEGORY}/alpha/${DIRNAME_HASH}_${BASENAME_NO_EXT}_alpha_%03d.png" &
        else
          echo ${FILENAME}, alpha single color, skipped
        fi
      fi

    else
      echo ${FILENAME} too small \(${IMAGE_WIDTH}x${IMAGE_HEIGHT}\), skipped
    fi

  else
    echo ${FILENAME}, already processed, skipped
  fi
  
done

wait_for_jobs
