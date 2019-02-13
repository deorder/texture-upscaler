#!/bin/bash
shopt -s extglob

THREADS="4"

# Examples
LR_INPUT_DIR="./output/LR"

# Ground truth
HR_INPUT_DIR="./output/HR"

MAX_TILE_COUNT=1000

TRAINING_PERCENTAGE=80
VALIDATION_PERCENTAGE=20

TRAINING_HR_OUTPUT_DIR="output_training/HR"
VALIDATION_HR_OUTPUT_DIR="output_validation/HR"

TRAINING_LR_OUTPUT_DIR="output_training/LR"
VALIDATION_LR_OUTPUT_DIR="output_validation/LR"

for OPTION in "$@"; do
  case ${OPTION} in
    -t=*|--threads=*)
    THREADS="${OPTION#*=}"
    shift
    ;;
    -l=*|--lr-input-dir=*)
    LR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -h=*|--hr-input-dir=*)
    HR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -t=*|--training-percentage=*)
    TRAINING_PERCENTAGE="${OPTION#*=}"
    shift
    ;;
    -v=*|--validation-percentage=*)
    VALIDATION_PERCENTAGE="${OPTION#*=}"
    shift
    ;;
    --training-hr-output-dir=*)
    TRAINING_HR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --validation-hr-output-dir=*)
    VALIDATION_HR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --training-lr-output-dir=*)
    TRAINING_LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --validation-lr-output-dir=*)
    VALIDATION_LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -c=*|--max-tile-count=*)
    MAX_TILE_COUNT="${OPTION#*=}"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
      echo "-l, --lr-input-dir \"<lr input dir>\" (default: ${LR_INPUT_DIR})"
      echo "-h, --hr-input-dir \"<hr input dir>\" (default: ${HR_INPUT_DIR})"
      echo "-t, --training-percentage \"<lr input dir>\" (default: ${TRAINING_PERCENTAGE})"
      echo "-v, --validation-percentage \"<hr input dir>\" (default: ${VALIDATION_PERCENTAGE})"
      echo "--training-hr-output-dir \"<training hr output dir>\" (default: ${TRAINING_HR_OUTPUT_DIR})"
      echo "--validation-hr-output-dir \"<validation hr output dir>\" (default: ${VALIDATION_HR_OUTPUT_DIR})"
      echo "--training-lr-output-dir \"<training lr output dir>\" (default: ${TRAINING_LR_OUTPUT_DIR})"
      echo "--validation-lr-output-dir \"<validation lr output dir>\" (default: ${VALIDATION_LR_OUTPUT_DIR})"
      echo "-c, --max-tile-count \"<number>\" (default: ${MAX_TILE_COUNT})"
      exit 1
    ;;
  esac
done

TILE_COUNT=$(find "${HR_INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png" \) | wc -l)

if [ "${TILE_COUNT}" -le "${MAX_TILE_COUNT}" ]; then
  TRAINING_COUNT=$((${TILE_COUNT} * ${TRAINING_PERCENTAGE}/100))
  VALIDATION_COUNT=$((${TILE_COUNT} * ${VALIDATION_PERCENTAGE}/100))
else
  TRAINING_COUNT=$((${MAX_TILE_COUNT} * ${TRAINING_PERCENTAGE}/100))
  VALIDATION_COUNT=$((${MAX_TILE_COUNT} * ${VALIDATION_PERCENTAGE}/100))
fi

mkdir -p "${TRAINING_HR_OUTPUT_DIR}" "${TRAINING_LR_OUTPUT_DIR}" "${VALIDATION_HR_OUTPUT_DIR}" "${VALIDATION_LR_OUTPUT_DIR}"

INDEX=0
while read FILENAME; do

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  RELATIVE_DIR=$(realpath --relative-to "${HR_INPUT_DIR}" "${DIRNAME}")

  if [ "${INDEX}" -lt "${TRAINING_COUNT}" ]; then
    echo training: ${RELATIVE_DIR}/${BASENAME_NO_EXT}
    cp -a "${HR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${TRAINING_HR_OUTPUT_DIR}/${BASENAME}"
    cp -a "${LR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${TRAINING_LR_OUTPUT_DIR}/${BASENAME}"
  else
    echo validation: ${RELATIVE_DIR}/${BASENAME_NO_EXT}
    cp -a "${HR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${VALIDATION_HR_OUTPUT_DIR}/${BASENAME}"
    cp -a "${LR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" "${VALIDATION_LR_OUTPUT_DIR}/${BASENAME}"
  fi

  ((INDEX++))
done < <(find "${HR_INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png" \) | shuf -n ${MAX_TILE_COUNT})

echo "finished"
