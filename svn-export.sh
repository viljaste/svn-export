#!/usr/bin/env bash

LOG_DIR=/var/log/svn-export

sudo mkdir -p "${LOG_DIR}"

LOG="${LOG_DIR}/svn-export.log"
LOG_DEBUG="${LOG_DIR}/debug.log"
LOG_ERROR="${LOG_DIR}/error.log"

log() {
  while read DATA; do
    echo "[$(date +"%D %T")] ${DATA}" | sudo tee -a "${LOG}" > /dev/null
  done
}

log_error() {
  while read DATA; do
    echo "[$(date +"%D %T")] ${DATA}" | sudo tee -a "${LOG_ERROR}" > /dev/null
  done
}

log_debug() {
  while read DATA; do
    echo "[$(date +"%D %T")] ${DATA}" | sudo tee -a "${LOG_DEBUG}" > /dev/null
  done
}

output() {
  local COLOR="${2}"

  if [ -z "${COLOR}" ]; then
    COLOR=2
  fi

  echo -e "$(tput setaf ${COLOR})${1}$(tput sgr 0)"
}

output_error() {
  local COLOR=1

  >&2 output "${1}" "${COLOR}"
}

output_debug() {
  local COLOR=3

  if [ ${DEBUG} ]; then
    local MESSAGE="${1}"

    echo -e "${MESSAGE}" > >(log_debug)
    echo -e "$(tput setaf "${COLOR}")${MESSAGE}$(tput sgr 0)"
  fi
}

help() {
  cat << EOF
svn-export: Usage: svn-export <revision_from:revision_to> [working_dir|repository_url] <destination>

svn-export 31337:HEAD exported_files
svn-export 31337:HEAD /my_project exported_files
svn-export 31337:HEAD http://my_project exported_files
EOF

  exit 1
}

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
  help
fi

unknown_command() {
  output_error "svn-export: Unknown command. See 'svn-export --help'"

  exit 1
}

if [ "${#}" -lt 2 ]; then
  unknown_command
fi

DESTINATION="${@: -1}"

output_debug "\${DESTINATION}: ${DESTINATION}"

REPOSITORY_URL=""

output_debug "\${REPOSITORY_URL}: ${REPOSITORY_URL}"

WORKING_DIR="$(pwd)"

output_debug "\${WORKING_DIR}: ${WORKING_DIR}"

TMP="$(mktemp -d)"

output_debug "\${TMP}: ${TMP}"

BASE_URL="$(svn info "${WORKING_DIR}" | grep "URL:" | awk '{ print $2 }')"

output_debug "\${BASE_URL}: ${BASE_URL}"

REVISION_FROM="$(echo "${1}" | cut -d ":" -f1)"

output_debug "\${REVISION_FROM}: ${REVISION_FROM}"

REVISION_TO="$(echo "${1}" | cut -d ":" -f2)"

output_debug "\${REVISION_TO}: ${REVISION_TO}"

DIFF="$(svn diff --summarize -r "${REVISION_FROM}:${REVISION_TO}" "${BASE_URL}" | awk '{ print $1 ":" $2 }')"

DELETED_FILES=""

for LINE in ${DIFF}; do
  output_debug "\${LINE}: ${LINE}"

  MODIFIER="$(echo "${LINE}" | cut -d ":" -f1)"

  output_debug "\${MODIFIER}: ${MODIFIER}"

  FILE_URL="$(echo "${LINE}" | awk -F : '{ st = index($0, ":"); print substr($0, st + 1) }')"

  output_debug "\${FILE_URL}: ${FILE_URL}"

  FILE_RELATIVE_PATH="${FILE_URL/${BASE_URL}}"

  if [ "${FILE_RELATIVE_PATH:0:1}" == '/' ]; then
    FILE_RELATIVE_PATH="$(echo "${FILE_RELATIVE_PATH}" | cut -c 2-)"
  fi

  output_debug "FILE_RELATIVE_PATH: ${FILE_RELATIVE_PATH}"

  if [ "${MODIFIER}" == "D" ]; then
    DELETED_FILES="${DELETED_FILES}\nsvn-export: Deleted file: ${FILE_RELATIVE_PATH}"

    continue
  fi

  FILE_RELATIVE_PATH_DIRECTORY="$(dirname "${FILE_RELATIVE_PATH}")"

  output_debug "FILE_RELATIVE_PATH_DIRECTORY: ${FILE_RELATIVE_PATH_DIRECTORY}"

  FILENAME="$(basename "${FILE_RELATIVE_PATH}")"

  output_debug "FILENAME: ${FILENAME}"

  cd "${TMP}"

  mkdir -p "${FILE_RELATIVE_PATH_DIRECTORY}"

  cd "${FILE_RELATIVE_PATH_DIRECTORY}"

  output "svn-export: Exporting file: ${FILE_RELATIVE_PATH}"

  svn export --depth empty -r "${REVISION_TO}" "${FILE_URL}" "${FILENAME}" > >(log) 2> >(log_error)

  cd "${WORKING_DIR}"
done

output "${DELETED_FILES}"
