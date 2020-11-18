#!/bin/bash

set -euo pipefail

docker pull quay.io/forem/forem:builder ||:
docker pull quay.io/forem/forem:production ||:
docker pull quay.io/forem/forem:testing ||:
docker pull quay.io/forem/forem:development ||:

# Build the builder image
docker build --target builder \
             --cache-from=quay.io/forem/forem:builder \
             --tag quay.io/forem/forem:builder .

# Build the production image
docker build --target production \
             --cache-from=quay.io/forem/forem:builder \
             --cache-from=quay.io/forem/forem:production \
             --tag quay.io/forem/forem:$(date +%Y%m%d) \
             --tag quay.io/forem/forem:${BUILDKITE_COMMIT:0:7} \
             --tag quay.io/forem/forem:production \
             --tag quay.io/forem/forem:latest .

# Build the testing image
docker build --target testing \
             --cache-from=quay.io/forem/forem:builder \
             --cache-from=quay.io/forem/forem:production \
             --cache-from=quay.io/forem/forem:testing \
             --tag quay.io/forem/forem:testing .

# Build the development image
docker build --target development \
             --cache-from=quay.io/forem/forem:builder \
             --cache-from=quay.io/forem/forem:production \
             --cache-from=quay.io/forem/forem:testing \
             --cache-from=quay.io/forem/forem:development \
             --tag quay.io/forem/forem:development .

# Push images to Quay
docker push quay.io/forem/forem:builder
docker push quay.io/forem/forem:production
docker push quay.io/forem/forem:testing
docker push quay.io/forem/forem:development
docker push quay.io/forem/forem:$(date +%Y%m%d)
docker push quay.io/forem/forem:${BUILDKITE_COMMIT:0:7}
docker push quay.io/forem/forem:latest
