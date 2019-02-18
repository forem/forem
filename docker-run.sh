#!/bin/bash

echo "##---"
echo "## This script will perform the following steps ... "
echo "##"
echo "## 1) Stop and remove any docker container with the name 'dev-to-postgres' and 'dev-to'"
echo "## 2) Build the dev.to docker image, with the name of 'dev-to'"
echo "## 3) Deploy the postgres container, mounting '_docker-storage/postgres' with the name 'dev-to-postgres'"
echo "## 4) Deploy the dev-to container, with the name of 'dev-to-app'"
echo "##---"

# Get the currrent repository dierctory
REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
# @TODO - get this from variable arguments
STORAGE_DIR="$REPO_DIR/_docker-storage"

# Postgresql data
POSTGRES_DIR="$STORAGE_DIR/postgresql-data"
# docker-run.sh script mode
RUN_MODE="DEV"


echo "##---"
echo "## Assuming the following settings ..."
echo "##"
echo "## RUN_MODE     = $RUN_MODE"
echo "## REPO_DIR     = $REPO_DIR"
echo "## STORAGE_DIR  = $STORAGE_DIR"
echo "## POSTGRES_DIR = $POSTGRES_DIR"
echo "##"
echo "## ALGOLIASEARCH_APPLICATION_ID  = $ALGOLIASEARCH_APPLICATION_ID"
echo "## ALGOLIASEARCH_SEARCH_ONLY_KEY = $ALGOLIASEARCH_SEARCH_ONLY_KEY"
echo "## ALGOLIASEARCH_API_KEY         = ${ALGOLIASEARCH_API_KEY:0:4}...<intentionally masked>"
echo "##---"

#
# Stop and remove existing containers
#
EXISTING_POSTGRES=$(docker ps -a | grep "dev-to-postgres" | awk '{print $1}')
EXISTING_DEVTO=$(docker ps -a | grep "dev-to-app" | awk '{print $1}')
if [[ ! -z "$EXISTING_POSTGRES" ]] || [[ ! -z "$EXISTING_DEVTO" ]]
then
	echo "##---"
	echo "## Removing docker containers with ID : $EXISTING_POSTGRES $EXISTING_DEVTO"
	echo "##---"

	# I dunno how docker does a race condition against the previous echo step
	# this works around that
	sleep 0.001

	# Stopping and removing containers
	docker stop $EXISTING_POSTGRES $EXISTING_DEVTO;
	docker rm $EXISTING_POSTGRES $EXISTING_DEVTO;
fi

#
# Build the dev-to container
# Exits on failure
#
echo "##---"
echo "## Building dev-to docker container ... "
echo "## If this is your first time running this build step, go grab a coffee - it will take a long while"
echo "## Alternatively, some paper swords with chairs : https://xkcd.com/303/"
echo "##---"
docker build -t dev-to . || exit $?

#
# Reset the postgresql folder
#
rm -R "$POSTGRES_DIR"

#
# Deploy postgresql container
#
echo "##---"
echo "## Deploying postgresql container"
echo "##---"
mkdir -p "$POSTGRES_DIR"
docker run -d --name dev-to-postgres -e POSTGRES_PASSWORD=devto -e POSTGRES_USER=devto -e POSTGRES_DB=PracticalDeveloper_development -v "$POSTGRES_DIR:/var/lib/postgresql/data" postgres:10.7-alpine

#
# Deploy dev-to container
#
echo "##---"
echo "## Deploying dev-to container"
echo "##---"

# # "Prod?"
# docker run -d -p 3000:3000 --name dev-to-app --link dev-to-postgres:db \
# -e DATABASE_URL=postgresql://devto:devto@db:5432/PracticalDeveloper_development \
# -e ALGOLIASEARCH_APPLICATION_ID="$ALGOLIASEARCH_APPLICATION_ID" -e ALGOLIASEARCH_SEARCH_ONLY_KEY="$ALGOLIASEARCH_SEARCH_ONLY_KEY" -e ALGOLIASEARCH_API_KEY="$ALGOLIASEARCH_API_KEY" \
# -e RACK_TIMEOUT_WAIT_TIMEOUT=10000 -e RACK_TIMEOUT_SERVICE_TIMEOUT=10000 -e STATEMENT_TIMEOUT=10000 \
# dev-to

# "Dev?"
docker run -it -p 3000:3000 --name dev-to-app --link dev-to-postgres:db \
-e DATABASE_URL=postgresql://devto:devto@db:5432/PracticalDeveloper_development \
-e ALGOLIASEARCH_APPLICATION_ID="$ALGOLIASEARCH_APPLICATION_ID" -e ALGOLIASEARCH_SEARCH_ONLY_KEY="$ALGOLIASEARCH_SEARCH_ONLY_KEY" -e ALGOLIASEARCH_API_KEY="$ALGOLIASEARCH_API_KEY" \
-e RACK_TIMEOUT_WAIT_TIMEOUT=10000 -e RACK_TIMEOUT_SERVICE_TIMEOUT=10000 -e STATEMENT_TIMEOUT=10000 \
dev-to


# setting the various timeouts to large numbers 10000 since the docker version of this app and database tend to be *extremely* slow.
# -p 3000:3000 exposes the port 3000 on the container to the host's port 3000. This lets us access our dev environment on our laptop at http://localhost:3000.
#
# -e RACK_TIMEOUT_WAIT_TIMEOUT=10000 -e RACK_TIMEOUT_SERVICE_TIMEOUT=10000 -e STATEMENT_TIMEOUT=10000 
# -e ALGOLIASEARCH_API_KEY=yourkey -e ALGOLIASEARCH_APPLICATION_ID=yourid -e ALGOLIASEARCH_SEARCH_ONLY_KEY=yourotherkey 
# -e DATABASE_URL=postgresql://devto:devto@db:5432/PracticalDeveloper_development dev.to:latest /bin/bash
