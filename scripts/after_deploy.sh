#!/bin/bash

COMMIT="$(git rev-parse HEAD | cut -c1-7)"

curl "https://api.honeycomb.io/1/markers/${HONEYCOMB_DATASET}" -X POST  \
    -H "X-Honeycomb-Team: ${HONEYCOMB_API_KEY}"  \
    -d '{"type":"deploy", "message":"'${COMMIT}'"}'
