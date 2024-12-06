#!/usr/bin/env bash

API_ENDPOINT="https://sub-account-testing.cloudinary.com/create_sub_account"

SDK_NAME="${1}"

CLOUD_DETAILS=$(curl -sS -d "{\"prefix\" : \"${SDK_NAME}\"}" "${API_ENDPOINT}")

echo "${CLOUD_DETAILS}" | ruby -e "require 'json'; c=JSON.parse(ARGF.read)['payload']; puts 'cloudinary://' + c['cloudApiKey'] + ':'+ c['cloudApiSecret'] + '@' + c['cloudName']"
