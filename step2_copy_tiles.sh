#!/bin/bash
shopt -s extglob

THREADS=4

RESIZE=100%
SUBDIVISIONS=4

FILTER=point
INTERPOLATE=Nearest

INPUT_POSTFIX=""

INDEX_FILE="./index.txt"

INPUT_DIR="./input_tiles"
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
      exit 1
    ;;
  esac
done

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

copy_task() {

  ENTRY="$@"

  DIRNAME=$(echo ${ENTRY} | cut -d':' -f3)
  DIRNAME_HASH=$(echo ${ENTRY} | cut -d':' -f1)
  BASENAME_NO_EXT=$(echo ${ENTRY} | cut -d':' -f2)

  IMAGE_WIDTH=$(echo ${ENTRY} | cut -d':' -f5)
  IMAGE_HEIGHT=$(echo ${ENTRY} | cut -d':' -f6)
  IMAGE_CHANNELS=$(echo ${ENTRY} | cut -d':' -f4)

  COLUMNS=$(echo ${ENTRY} | cut -d':' -f8)
  ROWS=$(echo ${ENTRY} | cut -d':' -f7)

  TILE_COUNT=$((${ROWS} * ${COLUMNS}))

  echo ${BASENAME_NO_EXT} ${DIRNAME} ${IMAGE_CHANNELS} ${DIRNAME_HASH}

  for TILE_INDEX in $(seq 0 $((${TILE_COUNT} - 1))); do
    convert "${INPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_${TILE_INDEX}${INPUT_POSTFIX}.png" -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_${TILE_INDEX}.png"
    if [ "${IMAGE_CHANNELS}" == "rgba" ] || [ "${IMAGE_CHANNELS}" == "srgba" ]; then
      convert "${INPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_alpha_${TILE_INDEX}${INPUT_POSTFIX}.png" -interpolate ${INTERPOLATE} -filter ${FILTER} -resize ${RESIZE} "${OUTPUT_DIR}/${DIRNAME_HASH}_${BASENAME_NO_EXT}_alpha_${TILE_INDEX}.png"
    fi
  done

}

while read ENTRY; do
 wait_for_jobs
 copy_task ${ENTRY} &
done < <(cat "${INDEX_FILE}")
      
wait_for_jobs
wait

echo "finished"
