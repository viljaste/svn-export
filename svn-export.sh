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

output_warning() {
  local MESSAGE="${1}"
  local COLOR=3

  output "${MESSAGE}" "${COLOR}"
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

REPOSITORY="$(svn info "${REPOSITORY}" 2> /dev/null | grep "^URL:" | awk '{ print $2 }')"

if [ -z "${REPOSITORY}" ]; then
  output_error "svn-export: Invalid repository"

  exit 1
fi

TARGET="${@: -1}"

if [ -d "${TARGET}" ]; then
  output_error "svn-export: Target directory already exists: ${TARGET}"
fi

mkdir -p "${TARGET}"

REVISION="${1}"

if [ "${#}" -gt 2 ]; then
  REVISION="${2}"
fi

REVISION_FROM="$(echo "${REVISION}" | cut -d ":" -f1)"
REVISION_TO="$(echo "${REVISION}" | cut -d ":" -f2)"

RESULTS="$(svn diff --summarize -r "${REVISION_FROM}:${REVISION_TO}" "${REPOSITORY}" 2> /dev/null | awk '{ print $1 ":" $2 }')"

if [ -z "${RESULTS}" ]; then
  output "svn-export: No results"

  exit 1
fi

DELETED_FILES=""

for LINE in ${RESULTS}; do
  if [ "$(echo "${LINE}" | cut -d ":" -f1)" == "D" ]; then
    DELETED_FILES="${DELETED_FILES}\nsvn-export: Deleted file: ${RELATIVE_PATH}"

    continue
  fi

  cd "${WORKING_DIR}"
  cd "${TARGET}"

  FILE="$(echo "${LINE}" | awk -F : '{ st = index($0, ":"); print substr($0, st + 1) }')"
  RELATIVE_PATH="${FILE/${REPOSITORY}}"

  if [ "${RELATIVE_PATH:0:1}" == '/' ]; then
    RELATIVE_PATH="$(echo "${RELATIVE_PATH}" | cut -c 2-)"
  fi

  DIRECTORY="$(dirname "${RELATIVE_PATH}")"

  if [ ! -d "${DIRECTORY}" ]; then
    mkdir -p "${DIRECTORY}"
  fi

  cd "${DIRECTORY}"

  output "svn-export: Exporting file: ${RELATIVE_PATH}"

  svn export --depth empty --force -r "${REVISION_TO}" "${FILE}" "$(basename "${RELATIVE_PATH}")" > /dev/null 2>&1
done

if [ ! -z "${DELETED_FILES}" ]; then
  output_warning "${DELETED_FILES}"
fi

cd "${WORKING_DIR}"
