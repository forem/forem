#!/bin/bash

REPOSITORY=https://github.com/thepracticaldev/dev.to_private/
REVISION="$(git rev-parse HEAD)"
curl -X POST -H "Content-Type: application/json" -d '{"environment":"production","repository":"'${REPOSITORY}'","revision":"'${REVISION}'"}' "https://airbrake.io/api/v4/projects/${AIRBRAKE_PROJECT_ID}/deploys?key=${AIRBRAKE_PROJECT_KEY}"
