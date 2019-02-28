#!/bin/bash
shopt -s extglob

THREADS=4

RESIZE=100%
OVERDRAW=64

FILTER=SincFast
INTERPOLATE=Bilinear

INPUT_POSTFIX=""

INDEX_FILE="./index.txt"

INPUT_DIR="./input_tiles"
OUTPUT_DIR="./output"

for OPTION in "$@"; do
  case ${OPTION} in
    -t=*|--threads=*)
    THREADS="${OPTION#*=}"
    shift
    ;;
    -i=*|--input-dir=*)
    INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -o=*|--output-dir=*)
    OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -x=*|--index-file=*)
    INDEX_FILE="${OPTION#*=}"
    shift
    ;;
    -r=*|--resize=*)
    RESIZE="${OPTION#*=}"
    shift
    ;;
    -f=*|--filter=*)
    FILTER="${OPTION#*=}"
    shift
    ;;
    -l=*|--interpolate=*)
    INTERPOLATE="${OPTION#*=}"
    shift
    ;;
    -d=*|--overdraw=*)
    OVERDRAW="${OPTION#*=}"
    shift
    ;;
    -p=*|--input-postfix=*)
    INPUT_POSTFIX="${OPTION#*=}"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
      echo "-i, --input-dir \"<input dir>\" (default: ${INPUT_DIR})"
      echo "-o, --output-dir \"<output dir>\" (default: ${OUTPUT_DIR})"
      echo "-x, --index-file \"<index file>\" (default: ${INDEX_FILE})"
      echo "-r, --resize \"<percentage>\" (default: ${RESIZE})"
      echo "-f, --filter \"<filter>\" (default: ${FILTER})"
      echo "-l, --interpolate \"<interpolate>\" (default: ${INTERPOLATE})"
      echo "-p, --input-postfix \"<string>\" (default: ${INPUT_POSTFIX})"
      echo "-d, --overdraw \"<pixels>\" (default: ${OVERDRAW})"
      exit 1
    ;;
  esac
done

wait_for_jobs() {
  local JOBLIST=($(jobs -p))
  if [ "${#JOBLIST[@]}" -gt "${THREADS}" ]; then
    for JOB in ${JOBLIST}; do
      echo Waiting for job ${JOB}...
      wait ${JOB}
    done
  fi
}

while read ENTRY; do

  OVERDRAW_WIDTH=${OVERDRAW}
  OVERDRAW_HEIGHT=${OVERDRAW}

  DIRNAME=$(echo ${ENTRY} | cut -d':' -f3)
  DIRNAME_HASH=$(echo ${ENTRY} | cut -d':' -f1)
  BASENAME_NO_EXT=$(echo ${ENTRY} | cut -d':' -f2)

  
  IMAGE_WIDTH=$(echo ${ENTRY} | cut -d':' -f5)
  IMAGE_HEIGHT=$(echo ${ENTRY} | cut -d':' -f6)
  IMAGE_CHANNELS=$(echo ${ENTRY} | cut -d':' -f4)
  
  COLUMNS=$(echo ${ENTRY} | cut -d':' -f8)
  ROWS=$(echo ${ENTRY} | cut -d':' -f7)

  TILE_INFO=$(identify -format '%[width] %[height]' "${INPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_0${INPUT_POSTFIX}.png")

  TILE_WIDTH=$(echo ${TILE_INFO} | cut -d' ' -f 1)
  TILE_HEIGHT=$(echo ${TILE_INFO} | cut -d' ' -f 2)

  echo ${BASENAME_NO_EXT} ${DIRNAME} ${IMAGE_CHANNELS} ${DIRNAME_HASH}

  mkdir -p "${OUTPUT_DIR}/${DIRNAME}"

  COMPOSITE_ARGS=""
  ALPHA_COMPOSITE_ARGS=""
  for TILE_ROW_INDEX in $(seq $((${ROWS} - 1)) -1 0); do
    for TILE_COLUMN_INDEX in $(seq $((${COLUMNS} - 1)) -1 0); do

      TILE_INDEX=$(((${TILE_ROW_INDEX} * ${COLUMNS}) + ${TILE_COLUMN_INDEX}))
      TILE_X1=$((${TILE_COLUMN_INDEX} * (${TILE_WIDTH} - ${OVERDRAW_WIDTH})))
      TILE_Y1=$((${TILE_ROW_INDEX} * (${TILE_HEIGHT} - ${OVERDRAW_HEIGHT})))
      TILE_X2=$((${TILE_X1} + ${TILE_WIDTH}))
      TILE_Y2=$((${TILE_Y1} + ${TILE_HEIGHT}))

      INPUT_FILENAME="${INPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_${TILE_INDEX}${INPUT_POSTFIX}.png"
      ALPHA_INPUT_FILENAME="${INPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_alpha_${TILE_INDEX}${INPUT_POSTFIX}.png"

      if [ "${COLUMNS}" -gt "1" ] || [ "${COLUMNS}" -gt "1" ]; then
        COMPOSITE_ARGS="${COMPOSITE_ARGS} \\( \"${INPUT_FILENAME}\" -clone 0 -compose CopyOpacity +matte -composite -repage +${TILE_X1}+${TILE_Y1} \\)"
        ALPHA_COMPOSITE_ARGS="${ALPHA_COMPOSITE_ARGS} \\( \"${ALPHA_INPUT_FILENAME}\" -clone 0 -compose CopyOpacity +matte -composite -repage +${TILE_X1}+${TILE_Y1} \\)"
      else
        COMPOSITE_ARGS="${COMPOSITE_ARGS} \\( \"${INPUT_FILENAME}\" -repage +${TILE_X1}+${TILE_Y1} \\)"
        ALPHA_COMPOSITE_ARGS="${ALPHA_COMPOSITE_ARGS} \\( \"${ALPHA_INPUT_FILENAME}\" -repage +${TILE_X1}+${TILE_Y1} \\)"
      fi

    done
  done
  
  if [ "${ROWS}" -gt "1" ]; then
    BLEND_WIDTH_ARGS="\\( -size ${TILE_WIDTH}x${OVERDRAW_HEIGHT} gradient: -append -rotate 180 \\) -composite -compose multiply"
  fi

  if [ "${COLUMNS}" -gt "1" ]; then
    BLEND_HEIGHT_ARGS="\\( -size ${TILE_HEIGHT}x${OVERDRAW_WIDTH} gradient: -append -rotate 90 \\) -composite -compose multiply"
  fi

  if [ "${COLUMNS}" -gt "1" ] || [ "${COLUMNS}" -gt "1" ]; then
    BLEND_ARGS="\\( -size ${TILE_WIDTH}x${TILE_HEIGHT} xc:white ${BLEND_HEIGHT_ARGS} ${BLEND_WIDTH_ARGS} -rotate 180 \\)"
    ALPHA_ARGS="${BLEND_ARGS} ${ALPHA_COMPOSITE_ARGS} -delete 0 -compose Over -mosaic"
    RGB_ARGS="${BLEND_ARGS} ${COMPOSITE_ARGS} -delete 0 -compose Over -mosaic"
  else
    ALPHA_ARGS="${ALPHA_COMPOSITE_ARGS} -mosaic"
    RGB_ARGS="${COMPOSITE_ARGS} -mosaic"
  fi

  if [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
    COMMAND="convert \\( ${RGB_ARGS} -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} \\) \\( ${ALPHA_ARGS} -colorspace gray -alpha off -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} \\) -compose copy-opacity -composite \"${OUTPUT_DIR}/${DIRNAME}/${BASENAME_NO_EXT}.png\""
  fi

  if [ "${IMAGE_CHANNELS}" == "rgb" ] || [ "${IMAGE_CHANNELS}" == "srgb" ]; then
    COMMAND="convert \\( ${RGB_ARGS} \\) -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} \"${OUTPUT_DIR}/${DIRNAME}/${BASENAME_NO_EXT}.png\""
  fi

  wait_for_jobs
  sh -c "${COMMAND}" &
  #echo "${COMMAND}"

done < <(cat "${INDEX_FILE}")

wait_for_jobs
wait

echo "finished"
