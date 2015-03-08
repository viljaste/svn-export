#!/usr/bin/env bash

WORKING_DIR="$(pwd)"

hash svn 2> /dev/null

if [ "${?}" -ne 0 ]; then
  echo "svn-export: svn command not found."

  exit 1
fi

help() {
  cat << EOF
svn-export: Usage: svn-export [SOURCE] <REVISION_FROM:REVISION_TO> <DESTINATION>

Options:
  -u, --username=""
  -p, --password=""
EOF

  exit 1
}

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
  help
fi

unknown_command() {
  echo "svn-export: Unknown command. See 'svn-export --help'"

  exit 1
}

ARGUMENTS=()

USERNAME=""
PASSWORD=""

while [ "${1}" != "" ]; do
  ARGUMENT="${1}"

  shift

  case "${ARGUMENT}" in
    "-u"|"--username")
      USERNAME="${1}";

      shift
      ;;
    "-p"|"--password")
      PASSWORD="${1}";

      shift
      ;;
    *)
      ARGUMENTS+=("${ARGUMENT}")
      ;;
  esac
done

set "${ARGUMENTS[@]}"

OPTIONS=""

if [ -n "${USERNAME}" ] && [ -n "${PASSWORD}" ]; then
  OPTIONS="--username ${USERNAME} --password ${PASSWORD} --no-auth-cache"
fi

if [ "${#}" -lt 2 ] || [ "${#}" -gt 3 ]; then
  unknown_command
fi

DESTINATION="${@: -1}"

if [ -d "${DESTINATION}" ]; then
  echo "svn-export: Destination directory already exists: ${DESTINATION}"

  exit 1
fi

mkdir -p "${DESTINATION}"

cd "${DESTINATION}"

DESTINATION="$(pwd)"

SOURCE="${WORKING_DIR}"

if [ "${#}" -gt 2 ]; then
  SOURCE="${1}"
fi

SOURCE="$(svn ${OPTIONS} --trust-server-cert --non-interactive info ${SOURCE} 2> /dev/null | grep ^URL: | awk '{ print $2 }')"

if [ -z "${SOURCE}" ]; then
  echo "svn-export: Invalid repository."

  exit 1
fi

REVISION="${1}"

if [ "${#}" -gt 2 ]; then
  REVISION="${2}"
fi

REVISION_FROM="$(echo ${REVISION} | cut -d ':' -f1)"
REVISION_TO="$(echo ${REVISION} | cut -d ':' -f2)"

RESULTS="$(svn ${OPTIONS} --trust-server-cert --non-interactive diff --summarize -r $((REVISION_FROM - 1)):${REVISION_TO} ${SOURCE} 2> /dev/null | awk '{ print $1 ":" $2 }')"

if [ -z "${RESULTS}" ]; then
  echo "svn-export: No results."

  exit 1
fi

echo "$(svn ${OPTIONS} --trust-server-cert --non-interactive info ${SOURCE} -r ${REVISION_TO} 2> /dev/null | grep ^Revision: | awk '{ print $2 }')" > "${DESTINATION}/REVISION.txt"

DELETED_FILES=""

for LINE in ${RESULTS}; do
  FILE="$(echo ${LINE} | awk -F : '{ st = index($0, ":"); print substr($0, st + 1) }')"
  RELATIVE_PATH="${FILE/${SOURCE}}"

  if [ "$(echo ${LINE} | cut -d ':' -f1)" == "D" ]; then
    DELETED_FILES="${DELETED_FILES}\nsvn-export: Deleted file: ${RELATIVE_PATH}"

    continue
  fi

  cd "${WORKING_DIR}"
  cd "${DESTINATION}"

  if [ "${RELATIVE_PATH:0:1}" == "/" ]; then
    RELATIVE_PATH="$(echo ${RELATIVE_PATH} | cut -c 2-)"
  fi

  DIRECTORY="$(dirname ${RELATIVE_PATH})"

  if [ ! -d "${DIRECTORY}" ]; then
    mkdir -p "${DIRECTORY}"
  fi

  cd "${DIRECTORY}"

  echo "svn-export: Exporting file: ${RELATIVE_PATH}"

  svn ${OPTIONS} --trust-server-cert --non-interactive export --depth empty --force -r "${REVISION_TO}" "${FILE}" "$(basename ${RELATIVE_PATH})" > /dev/null 2>&1
done

if [ ! -z "${DELETED_FILES}" ]; then
  echo -e "${DELETED_FILES}"
fi

cd "${WORKING_DIR}"
