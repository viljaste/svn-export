#!/usr/bin/env bash

WORKING_DIR="$(pwd)"

if [ "${1}" == "-h" ] || [ "${1}" == "--help" ]; then
  cat << EOF
    svn-export 31337:HEAD archive
EOF

  exit 1
fi

case "${1}" in
  -r)
    mailcatcher "${@:2}"
  ;;
  *)
    echo "svn-export: Unknown command. See 'svn-export --help'"

    exit 1
  ;;
esac
