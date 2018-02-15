#!/bin/bash

LANGS=( "enUS" "deDE" "frFR" "esES" "itIT" "ruRU" "koKR" "zhCN" "zhTW" "esMX" "ptBR" )

ROOT=$(pwd)
if [ "${ROOT: -8}" == "/scripts" ]; then
  ROOT="${ROOT::-8}"
fi

INCLUDE_API_FILE="${ROOT}/scripts/api.token.sh"

if [ ! -f "${INCLUDE_API_FILE}" ]; then
  echo "\033[1;31mNo ${INCLUDE_API_FILE} file found!\033[m"
  exit 1
fi

source "${INCLUDE_API_FILE}"

if [ -z ${API_TOKEN} ]; then
  echo -e "\033[1;31mNo API Token found!\033[m"
  exit 0
fi
if [ -z ${API_PROJECT_ID} ]; then
  echo -e "\033[1;31mNo API Porject ID found!\033[m"
  exit 0
fi

API_URL="https://wow.curseforge.com/api/projects/${API_PROJECT_ID}/localization/export"
LOCALE_PATH="${ROOT}/locale"

for i in "${LANGS[@]}"
do

  if [ $i == "enUS" ]; then
    LOCALE_DEFAULT="true"
  else
    LOCALE_DEFAULT="false"
  fi

  LOCALE_FILE="${LOCALE_PATH}/Localization.$i.lua"

  echo "Fetching translation for $i"
  RESP=$($(which curl) --header "X-Api-Token: ${API_TOKEN}" --silent "${API_URL}?lang=$i")

  echo "Writing ${LOCALE_FILE}"
  echo "local L = LibStub('AceLocale-3.0'):NewLocale('${PROJECT_ID}', '$i', ${LOCALE_DEFAULT})" > "${LOCALE_FILE}"
  echo "if not L then return end" >> "${LOCALE_FILE}"
  echo "" >> "${LOCALE_FILE}"
  echo "${RESP}" >> "${LOCALE_FILE}"
done

echo -e "\033[1;32m[OK] All trnalsations has been updated\033[m"

exit 0
