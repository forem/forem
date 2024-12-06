#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

RUBY_VER=$(ruby -v | head -n 1 | cut -d ' ' -f 2);
SDK_VER=$(grep -oiP '(?<=VERSION = ")([a-zA-Z0-9\-.]+)(?=")' lib/cloudinary/version.rb)


bash "${DIR}"/allocate_test_cloud.sh "Ruby ${RUBY_VER} SDK ${SDK_VER}"
