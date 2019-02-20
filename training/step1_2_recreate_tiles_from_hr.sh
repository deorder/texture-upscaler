#!/bin/bash
shopt -s extglob

THREADS="16"

# Ground truth
HR_INPUT_DIR="./input/HR"

# Examples
LR_SCALE=25%
LR_FILTER=Catrom
LR_INTERPOLATE=Catrom
LR_OUTPUT_DIR="./output/LR.rescaled"


for OPTION in "$@"; do
  case ${OPTION} in
    -t=*|--threads=*)
    THREADS="${OPTION#*=}"
    shift
    ;;
    -c=*|--min-colors=*)
    MIN_COLORS="${OPTION#*=}"
    shift
    ;;
    -l=*|--lr-output-dir=*)
    LR_OUTPUT_DIR="${OPTION#*=}"
    shift
    ;;
    -h=*|--hr-input-dir=*)
    HR_INPUT_DIR="${OPTION#*=}"
    shift
    ;;
    --lr-scale-=*)
    LR_SCALE="${OPTION#*=}"
    shift
    ;;
    --lr-filter=*)
    LR_FILTER="${OPTION#*=}"
    shift
    ;;
    --lr-interpolate-=*)
    LR_INTERPOLATE="${OPTION#*=}"
    shift
    ;;
    *)
      echo "usage: $@ ..."
      echo "-t, --threads \"<number>\" (default: ${THREADS})"
      echo "-h, --hr-input-dir \"<hr output dir>\" (default: ${HR_INPUT_DIR})"
      echo "-l, --lr-output-dir \"<lr output dir>\" (default: ${LR_OUTPUT_DIR})"
      echo "--lr-scale \"<percentage>\" (default: ${LR_SCALE})"
      echo "--lr-filter \"<filter>\" (default: ${LR_FILTER})"
      echo "--lr-interpolate \"<interpolate>\" (default: ${LR_INTERPOLATE})"
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

recreate_task() {

  FILENAME="$@"

  DIRNAME=$(dirname "${FILENAME}")

  BASENAME=$(basename "${FILENAME}")
  BASENAME_NO_EXT="${BASENAME%.*}"

  RELATIVE_DIR=$(realpath --relative-to "${HR_INPUT_DIR}" "${DIRNAME}")

  echo ${RELATIVE_DIR}/${BASENAME_NO_EXT}

  mkdir -p "${LR_OUTPUT_DIR}/${RELATIVE_DIR}"

  convert "${HR_INPUT_DIR}/${RELATIVE_DIR}/${BASENAME}" -interpolate ${LR_INTERPOLATE} -filter ${LR_FILTER} -resize ${LR_SCALE} "${LR_OUTPUT_DIR}/${RELATIVE_DIR}/${BASENAME}"

  sleep 0.5
  
}

while read FILENAME; do
 wait_for_jobs
 recreate_task ${FILENAME} &
done < <(find "${HR_INPUT_DIR}" \( -iname "*.dds" -or -iname "*.png" \))

wait_for_jobs
wait

echo "finished"
