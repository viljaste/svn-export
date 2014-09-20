#!/usr/bin/env bash

WORKING_DIR="$(pwd)"

output() {
  local MESSAGE="${1}"
  local COLOR="${2}"

  if [ -z "${COLOR}" ]; then
    COLOR=2
  fi

  echo -e "$(tput setaf ${COLOR})${MESSAGE}$(tput sgr 0)"
}

output_error() {
  local MESSAGE="${1}"
  local COLOR=1

  >&2 output "${MESSAGE}" "${COLOR}"
}

help() {
  cat << EOF
svn-export: Usage: svn-export [REPOSITORY] <REVISION_FROM:REVISION_TO> <TARGET>
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

if [ "${#}" -lt 2 ] || [ "${#}" -gt 3 ]; then
  unknown_command
fi

REPOSITORY="${WORKING_DIR}"

if [ "${#}" -gt 2 ]; then
  REPOSITORY="${1}"
fi

REPOSITORY="$(svn info "${REPOSITORY}" 2> /dev/null | grep "URL:" | awk '{ print $2 }')"

if [ -z "${REPOSITORY}" ]; then
  output_error "svn-export: Invalid repository"

  exit 1
fi

TARGET="${@: -1}"

if [ ! -d "${TARGET}" ]; then
  output "svn-export: Creating directory: ${TARGET}"

  mkdir -p "${TARGET}"
fi

cd "${TARGET}"

REVISION="${1}"

if [ "${#}" -gt 2 ]; then
  REVISION="${2}"
fi

REVISION_FROM="$(echo "${REVISION}" | cut -d ":" -f1)"
REVISION_TO="$(echo "${REVISION}" | cut -d ":" -f2)"

RESULT="$(svn diff --summarize -r "${REVISION_FROM}:${REVISION_TO}" "${REPOSITORY}" 2> /dev/null | awk '{ print $1 ":" $2 }')"

if [ -z "${RESULT}" ]; then
  output "svn-export: No results"

  exit 1
fi

DELETED_FILES=""

for LINE in ${RESULT}; do
  MODIFIER="$(echo "${LINE}" | cut -d ":" -f1)"

  FILE_URL="$(echo "${LINE}" | awk -F : '{ st = index($0, ":"); print substr($0, st + 1) }')"

  FILE_RELATIVE_PATH="${FILE_URL/${REPOSITORY}}"

  if [ "${FILE_RELATIVE_PATH:0:1}" == '/' ]; then
    FILE_RELATIVE_PATH="$(echo "${FILE_RELATIVE_PATH}" | cut -c 2-)"
  fi

  if [ "${MODIFIER}" == "D" ]; then
    DELETED_FILES="${DELETED_FILES}\nsvn-export: Deleted file: ${FILE_RELATIVE_PATH}"

    continue
  fi

  FILE_RELATIVE_PATH_DIRECTORY="$(dirname "${FILE_RELATIVE_PATH}")"

  FILENAME="$(basename "${FILE_RELATIVE_PATH}")"

  mkdir -p "${FILE_RELATIVE_PATH_DIRECTORY}"

  cd "${FILE_RELATIVE_PATH_DIRECTORY}"

  output "svn-export: Exporting file: ${FILE_RELATIVE_PATH}"

  svn export --depth empty -r "${REVISION_TO}" "${FILE_URL}" "${FILENAME}" > /dev/null
done

output "${DELETED_FILES}"

cd "${WORKING_DIR}"
