#!/bin/bash

bin_path="${HOME}/.local/bin"

if [ "$EUID" -ne 0 ]; then
  echo "You are using this script as normal user, all changes will be avaiable only for your user."
  read -p "Do you want to proceed? (y/N) " yn
  case $yn in
    [yYsS] ) 
      bin_path="${HOME}/.local/bin";
      echo "Remember that you must add ${HOME}/.local/bin directory to your path to launch site2app from command line."
      ;;
    * ) 
      echo "Aborted";
      exit 1;
  esac
else
  echo "You are using this script as normal user, all changes will be avaiable only for your user."
  read -p "Do you want to proceed? (y/N) " yn
  case $yn in
    [yYsS] ) 
      bin_path="/usr/local/bin";
      ;;
    * ) 
      echo "Aborted";
      exit 1;
  esac
fi
echo "Creating folders ..."
[[ ! -d "${bin_path}" ]] && mkdir -p "${bin_path}"

echo "Copy bin ..."
cp ./bin/site2app "${bin_path}/site2app"
chmod +x "${bin_path}/site2app"
echo "Installation completed, print help"
site2app --help
exit 0
