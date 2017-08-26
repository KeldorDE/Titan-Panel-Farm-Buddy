#!/bin/bash

API_PROJECT_ID="274538"
API_URL="https://wow.curseforge.com/api/projects/${API_PROJECT_ID}/localization/export"

ROOT=$(pwd)
if [ "${ROOT: -8}" == "/scripts" ]; then
  ROOT="${ROOT::-8}"
fi

INCLUDE_API_FILE="${ROOT}/scripts/api.token.sh"

if [ ! -f "${INCLUDE_API_FILE}" ];then
  echo "\033[1;31mNo ${INCLUDE_API_FILE} file found!\033[m"
  exit 1
fi

source "${INCLUDE_API_FILE}"

if [ -z ${API_TOKEN} ]; then
  echo -e "\033[1;31mNo API Token found!\033[m"
  exit 0
fi

LOCALE_PATH="${ROOT}/locale"
LOCALE_EN="${LOCALE_PATH}/Localization.lua"
LOCALE_DE="${LOCALE_PATH}/Localization.DE.lua"

echo "Fetching translation for enUS"
RESP_EN=$($(which curl) --header "X-Api-Token: ${API_TOKEN}" --silent "${API_URL}?lang=enUS")

echo "Fetching translation for deDE"
RESP_DE=$($(which curl) --header "X-Api-Token: ${API_TOKEN}" --silent "${API_URL}?lang=deDE")

echo "Writing ${LOCALE_EN}"
echo "local L = LibStub('AceLocale-3.0'):NewLocale('Titan', 'deDE')" > "${LOCALE_EN}"
echo "if not L then return end" >> "${LOCALE_EN}"
echo "" >> "${LOCALE_EN}"
echo "${RESP_EN}" >> "${LOCALE_EN}"

echo "Writing ${LOCALE_DE}"
echo "local L = LibStub('AceLocale-3.0'):NewLocale('Titan', 'deDE')" > "${LOCALE_DE}"
echo "if not L then return end" >> "${LOCALE_DE}"
echo "" >> "${LOCALE_DE}"
echo "${RESP_DE}" >> "${LOCALE_DE}"

echo -e "\033[1;32m[OK] All trnalsations has been updated\033[m"

exit 0