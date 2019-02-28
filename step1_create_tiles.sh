#!/bin/bash
shopt -s extglob

THREADS=4

RESIZE=100%
OVERDRAW=16

TILE_WIDTH=256
TILE_HEIGHT=256

FILTER=point
INTERPOLATE=Nearest

INDEX_FILE="./index.txt"

INPUT_DIR="./input"
OUTPUT_DIR="./output_tiles"

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
    -w=*|--tile-width=*)
    TILE_WIDTH="${OPTION#*=}"
    shift
    ;;
    -h=*|--tile-height=*)
    TILE_HEIGHT="${OPTION#*=}"
    shift
    ;;
    -d=*|--overdraw=*)
    OVERDRAW="${OPTION#*=}"
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
      echo "-w, --tile-width \"<pixels>\" (default: ${TILE_WIDTH})"
      echo "-h, --tile-height \"<pixels>\" (default: ${TILE_HEIGHT})"
      echo "-d, --overdraw \"<pixels>\" (default: ${OVERDRAW})"
      exit 1
    ;;
  esac
done

:> "${INDEX_FILE}"
mkdir -p "${OUTPUT_DIR}"

wait_for_jobs() {
  local JOBLIST=($(jobs -p))
  if [ "${#JOBLIST[@]}" -gt "${THREADS}" ]; then
    for JOB in ${JOBLIST}; do
      echo Waiting for job ${JOB}...
      wait ${JOB}
    done
  fi
}

create_tiles_task() {

  INPUT_PATH="$1"

  IMAGE_WIDTH="$3"
  IMAGE_HEIGHT="$4"
  IMAGE_CHANNELS="$5"

  OUTPUT_BASENAME="$2"

  ROWS=$((${IMAGE_HEIGHT} / ${TILE_HEIGHT}))
  if [ "${ROWS}" -le 0 ]; then
    ROWS=1
  fi
  COLUMNS=$((${IMAGE_WIDTH} / ${TILE_WIDTH}))
  if [ "${COLUMNS}" -le 0 ]; then
    COLUMNS=1
  fi

  if [ "${IMAGE_CHANNELS}" == "rgb" ] || [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgb" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
    for TILE_COLUMN_INDEX in $(seq 0 $((${COLUMNS} - 1))); do
      for TILE_ROW_INDEX in $(seq 0 $((${ROWS} - 1))); do

        TILE_INDEX=$(((${TILE_ROW_INDEX} * ${COLUMNS}) + ${TILE_COLUMN_INDEX}))
        TILE_X1=$((${TILE_COLUMN_INDEX} * ${TILE_WIDTH}))
        TILE_Y1=$((${TILE_ROW_INDEX} * ${TILE_HEIGHT}))
        TILE_X2=$(((${TILE_COLUMN_INDEX} * ${TILE_WIDTH}) + ${TILE_WIDTH}))
        TILE_Y2=$(((${TILE_ROW_INDEX} * ${TILE_HEIGHT}) + ${TILE_HEIGHT}))

        convert "${INPUT_PATH}" -alpha off -crop $((${TILE_WIDTH} + ${OVERDRAW}))x$((${TILE_HEIGHT} + ${OVERDRAW}))+${TILE_X1}+${TILE_Y1} +repage +adjoin -define png:color-type=2 -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} "${OUTPUT_BASENAME}_${TILE_INDEX}.png"

        if [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
          convert "${INPUT_PATH}" -alpha extract -crop $((${TILE_WIDTH} + ${OVERDRAW}))x$((${TILE_HEIGHT} + ${OVERDRAW}))+${TILE_X1}+${TILE_Y1} +repage +adjoin -define png:color-type=2 -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} "${OUTPUT_BASENAME}_alpha_${TILE_INDEX}.png"
        fi

      done
    done

  else
    echo "${FILENAME} is ${IMAGE_CHANNELS}, skipping"
  fi

}

while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")
  BASENAME_NO_EXT=$(basename "${FILENAME%.*}")
  DIRNAME_HASH=$(echo ${DIRNAME} | md5sum | cut -d' ' -f1)

  IMAGE_INFO=$(identify -format '%[width]:%[height]:%[channels]' "${FILENAME}")
  IMAGE_WIDTH=$(echo ${IMAGE_INFO} | cut -d':' -f1)
  IMAGE_HEIGHT=$(echo ${IMAGE_INFO} | cut -d':' -f2)
  IMAGE_CHANNELS=$(echo ${IMAGE_INFO} | cut -d':' -f3)

  wait_for_jobs
  echo ${FILENAME}
  create_tiles_task "${FILENAME}" "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}" ${IMAGE_WIDTH} ${IMAGE_HEIGHT} ${IMAGE_CHANNELS} &

  ROWS=$((${IMAGE_HEIGHT} / ${TILE_HEIGHT}))
  if [ "${ROWS}" -le 0 ]; then
    ROWS=1
  fi
  COLUMNS=$((${IMAGE_WIDTH} / ${TILE_WIDTH}))
  if [ "${COLUMNS}" -le 0 ]; then
    COLUMNS=1
  fi

  RELATIVE_DIR=$(realpath --relative-to "${INPUT_DIR}" "${DIRNAME}")

  if [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
    echo "${DIRNAME_HASH}:${BASENAME_NO_EXT}:${RELATIVE_DIR}:rgba:${IMAGE_WIDTH}:${IMAGE_HEIGHT}:${ROWS}:${COLUMNS}" >> "${INDEX_FILE}"
  elif [ "${IMAGE_CHANNELS}" == "rgb" ] || [ "${IMAGE_CHANNELS}" == "srgb" ]; then
    echo "${DIRNAME_HASH}:${BASENAME_NO_EXT}:${RELATIVE_DIR}:rgb:${IMAGE_WIDTH}:${IMAGE_HEIGHT}:${ROWS}:${COLUMNS}" >> "${INDEX_FILE}"
  fi

done < <(find "${INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png"  \))

wait_for_jobs
wait

echo "finished"
