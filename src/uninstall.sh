#!/bin/bash

bin_path="${HOME}/.local/bin"

echo "Check user bin file ..."
if [[ -f "${bin_path}/site2app" ]]; then
  echo "Remove bin file from user bin folder ..."
  rm -f "${bin_path}/site2app"
fi

if [ "$EUID" -ne 0 ]; then
  echo "You are using this script as normal user, this script can only check if the file exists globally but cannot remove them."
  echo "If you want to remove files globally execute this script with sudo."
fi

bin_path="/usr/local/bin";
echo "Check bin file ..."
if [[ -f "${bin_path}/site2app" ]]; then
  if [ "$EUID" -ne 0 ]; then
    echo "Remove bin file from bin folder ..."
    rm -f "${bin_path}/site2app"
  else
    echo "You need to manually remove file: ${bin_path}/site2app"
  fi
fi

echo "Uninstall completed"
echo "This script does not deleted file created by site2app application. You must delete them manually."
exit 0
