#!/bin/bash

###########################################
#
# Interactive mode script handling
#
###########################################

if [ "$1" = "INTERACTIVE-DEMO" ]
then
	# echo "#---"
	# echo "# Starting up INTERACTIVE-DEMO mode"
	# echo "#---"

	# Configure RUN_MODE as DEMO
	RUN_MODE="DEMO"

	echo "|---"
	echo "|"
	echo "| Welcome to DEV.TO interactive docker demo setup guide."
	echo "|"
	echo "| For this container to work, we will need at minimum ALGOLIA API keys"
	echo "| For logins to work, we will need either GITHUB or TWITTER API keys"
	echo "|"
	echo "| See ( https://docs.dev.to/getting-started/config-env/ ) "
	echo "| for instructions on how to get the various API keys "
	echo "|"
	echo "| Once you got your various API keys, please proceed to the next step"
	echo "|"
	echo "|---"

	echo "|---"
	echo "| Setting up ALGOLIASEARCH keys (required)"
	echo "|---"
	echo -n "| Please indicate your ALGOLIASEARCH_APPLICATION_ID : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export ALGOLIASEARCH_APPLICATION_ID="$INPUT_KEY"
	fi

	echo -n "| Please indicate your ALGOLIASEARCH_SEARCH_ONLY_KEY : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export ALGOLIASEARCH_SEARCH_ONLY_KEY="$INPUT_KEY"
	fi

	echo -n "| Please indicate your ALGOLIASEARCH_API_KEY (aka admin key) : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export ALGOLIASEARCH_API_KEY="$INPUT_KEY"
	fi

	echo "|---"
	echo "| Setting up GITHUB keys"
	echo "| (OPTIONAL, leave blank and press enter to skip)"
	echo "|---"
	echo -n "| Please indicate your GITHUB_KEY : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export GITHUB_KEY="$INPUT_KEY"
	fi

	echo -n "| Please indicate your GITHUB_SECRET : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export GITHUB_SECRET="$INPUT_KEY"
	fi

	echo -n "| Please indicate your TWITTER_KEY : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export TWITTER_KEY="$INPUT_KEY"
	fi

	echo -n "| Please indicate your TWITTER_SECRET : "
	read INPUT_KEY
	if [ ! -z "$INPUT_KEY" ]
	then
		export TWITTER_SECRET="$INPUT_KEY"
	fi

fi

###########################################
#
# Script header guide
#
###########################################

echo "#---"
echo "#"
echo "# This script will perform the following steps ... "
echo "#"
echo "# 1) Stop and remove any docker container with the name 'dev-to-postgres' and 'dev-to'"
echo "# 2) Reset any storage directories if RUN_MODE starts with 'RESET-'"
echo "# 3) Build the dev.to docker image, with the name of 'dev-to:dev' or 'dev-to:demo'"
echo "# 4) Deploy the postgres container, mounting '_docker-storage/postgres' with the name 'dev-to-postgres'"
echo "# 5) Deploy the dev-to container, with the name of 'dev-to-app', and sets up its port to 3000"
echo "#"
echo "# To run this script properly, execute with the following (inside the dev.to repository folder)..."
echo "# './docker-run.sh [RUN_MODE] [Additional docker environment arguments]'"
echo "#"
echo "# Alternatively to run this script in 'interactive mode' simply run"
echo "# './docker-run.sh INTERACTIVE-DEMO'"
echo "#"
echo "#---"
echo "#---"
echo "#"
echo "# RUN_MODE can either be the following"
echo "#"
echo "# - 'DEV'  : Start up the container into bash, with a quick start guide"
echo "# - 'DEMO' : Start up the container, and run dev.to (requires ALGOLIA environment variables)"
echo "# - 'RESET-DEV'   : Resets postgresql and upload data directory for a clean deployment, before running as DEV mode"
echo "# - 'RESET-DEMO'  : Resets postgresql and upload data directory for a clean deployment, before running as DEMO mode"
echo "# - 'INTERACTIVE-DEMO' : Runs this script in 'interactive' mode to setup the 'DEMO'"
echo "#"
echo "# So for example to run a development container in bash it's simply"
echo "# './docker-run.sh DEV'"
echo "#"
echo "# To run a simple demo, with some dummy data (replace <?> with the actual keys)"
echo "# './docker-run.sh DEMO -e ALGOLIASEARCH_APPLICATION_ID=<?> -e ALGOLIASEARCH_SEARCH_ONLY_KEY=<?> -e ALGOLIASEARCH_API_KEY=<?>'"
echo "#"
echo "# Finally to run a working demo, you will need to provide either..."
echo "# './docker-run.sh .... -e GITHUB_KEY=<?> -e GITHUB_SECRET=<?>"
echo "#"
echo "# And / Or ..."
echo "# './docker-run.sh .... -e TWITTER_KEY=<?> -e TWITTER_SECRET=<?>"
echo "#"
echo "# Note that all of this can also be configured via ENVIRONMENT variables prior to running the script"
echo "#"
echo "#---"

###########################################
#
# Core script logic
#
###########################################

#
# Arguments / Environment handling
#

# Terminate without argument
if [ -z "$1" ]
then
	# Invalid RUN_MODE
	echo "#---"
	echo "# [FATAL ERROR] Missing RUN_MODE argument (see example above)"
	echo "#---"
	exit 1
fi

# Initialize : docker-run.sh RUN_MODE
# also parses it from argument array
if [ -z "$RUN_MODE" ]
then
	RUN_MODE="DEMO"
fi
# Argument processing
if [ "$1" = "DEMO" ] || [ "$1" = "DEV" ] || [ "$1" = "RESET-DEV" ] || [ "$1" = "RESET-DEMO" ]
then
	# The mode is passed into the command line script, process it
	RUN_MODE="$1"
	# Process argument array without RUN_MODE
	ARG_ARRAY_STR="${@:2}"
else
	if [ "$1" = "INTERACTIVE-DEMO" ]
	then
		RUN_MODE="DEMO"
		# Process argument array without RUN_MODE
		ARG_ARRAY_STR="${@:2}"
	else
		# Process argument array with $0
		ARG_ARRAY_STR="${@:1}"
	fi
fi
if [ "$RUN_MODE" = "DEMO" ] || [ "$RUN_MODE" = "DEV" ] || [ "$RUN_MODE" = "RESET-DEV" ] || [ "$RUN_MODE" = "RESET-DEMO" ]
then
	# OK we validated run mode
	RUN_MODE=$RUN_MODE
else
	# Invalid RUN_MODE
	echo "#---"
	echo "# [FATAL ERROR] Invalid RUN_MODE : $RUN_MODE (see example above)"
	echo "#---"
	exit 2
fi

# Initialize : the currrent repository directory (and navigate to it)
if [ -z "$REPO_DIR" ]
then
	REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi
cd "$REPO_DIR";

# Initialize : the general storage directory (used to magic bash the upload / postgres directory)
if [ -z "$STORAGE_DIR" ]
then
	STORAGE_DIR="$REPO_DIR/_docker-storage"
fi

# Initialize : Postgresql data directory
if [ -z "$POSTGRES_DIR" ]
then
	POSTGRES_DIR="$STORAGE_DIR/postgresql-data/"
fi

# Initialize : dev-to public upload data
if [ -z "$UPLOAD_DIR" ]
then
	UPLOAD_DIR="$STORAGE_DIR/public-upload/"
fi

echo "#---"
echo "# Ok, to start with - lets assume the following settings (provided or auto default)..."
echo "#"
echo "# RUN_MODE     = $RUN_MODE"
echo "# REPO_DIR     = $REPO_DIR"
echo "# STORAGE_DIR  = $STORAGE_DIR"
echo "# UPLOAD_DIR   = $UPLOAD_DIR"
echo "# POSTGRES_DIR = $POSTGRES_DIR"
echo "#"
echo "# PS  : These settings can also be overwritten by ENVIRONMENT variables, extremely useful in a CI setup =)"
echo "#---"

#
# ENV variables to support forwarding, and the compulsory list from bash script to docker (if detected)
#
ENV_FORWARDING_LIST=(
	# ALGOLIASEARCH (required for deployment)
	"ALGOLIASEARCH_APPLICATION_ID"
	"ALGOLIASEARCH_SEARCH_ONLY_KEY"
	"ALGOLIASEARCH_API_KEY"
	# login via GITHUB
	"GITHUB_KEY"
	"GITHUB_SECRET"
	# login via TWITTER
	"TWITTER_KEY"
	"TWITTER_SECRET"
	# PUSHER integration
	"PUSHER_APP_ID"
	"PUSHER_KEY"
	"PUSHER_SECRET"
	"PUSHER_CLUSTER"
	# @TODO : anything else to pass forward? S3<?>
)
ENV_FORWARDING_DEMO_COMPULSORY_LIST=(
	# ALGOLIASEARCH (required for deployment)
	"ALGOLIASEARCH_APPLICATION_ID"
	"ALGOLIASEARCH_SEARCH_ONLY_KEY"
	"ALGOLIASEARCH_API_KEY"
)

#
# dev.to docker command flags to pass forward
#
DEVTO_DOCKER_FLAGS="$ARG_ARRAY_STR"

#
# Scan for ENV variables to forward
#
echo "#---"
echo "# Lets scan for dev.to environment variables that will automatically be passed"
echo "# forward into the container if present (very useful for CI testing)"
echo "#---"
for i in "${ENV_FORWARDING_LIST[@]}"
do
	if [[ $DEVTO_DOCKER_FLAGS == *"$i"* ]]
	then
		echo "[detected in arguments] - $i"
		continue
	fi

	if [ ! -z "$(printenv $i)" ]
	then
		echo "[detected env variable] - $i"
		DEVTO_DOCKER_FLAGS="$DEVTO_DOCKER_FLAGS -e $i=$(printenv $i)"
		continue
	fi

	echo "[skipped env variable]  - $i"
done

#
# Check for DEMO compulsory list
#
if [[ "$RUN_MODE" == *"DEMO"* ]]
then
	# Iterate compulsory list
	for i in "${ENV_FORWARDING_DEMO_COMPULSORY_LIST[@]}"
	do
		# Exit if not found
		if [[ $DEVTO_DOCKER_FLAGS != *"$i"* ]]
		then
			echo "#---"
			echo "# [FATAL ERROR] Missing required DEMO env setting / argument for $i (see example above)"
			echo "#---"
			exit 3
		fi
	done
fi

#
# Stop and remove existing containers
#
EXISTING_POSTGRES=$(docker ps -a | grep "dev-to-postgres" | awk '{print $1}')
EXISTING_DEVTO=$(docker ps -a | grep "dev-to-app" | awk '{print $1}')
if [[ ! -z "$EXISTING_POSTGRES" ]] || [[ ! -z "$EXISTING_DEVTO" ]]
then
	echo "#---"
	echo "# Removing dev-to-postgres / dev-to-app containers"
	echo "# Found the following : $EXISTING_POSTGRES $EXISTING_DEVTO"
	echo "#---"

	# I dunno how docker does a race condition against the previous echo step
	# this works around that
	sleep 0.001

	# Stopping and removing containers
	docker stop $EXISTING_POSTGRES $EXISTING_DEVTO;
	docker rm $EXISTING_POSTGRES $EXISTING_DEVTO;
fi

#
# Reset the postgresql / upload folder
#
if [ "$RUN_MODE" = "RESET-DEV" ] || [ "$RUN_MODE" = "RESET-DEMO" ]
then
	echo "#---"
	echo "# Detected RESET based run mode : $RUN_MODE"
	echo "#"
	echo "# Will delete the following directory X_X "
	echo "# - $UPLOAD_DIR"
	echo "# - $POSTGRES_DIR"
	echo "#"
	echo "# And change RUN_MODE to : ${RUN_MODE:6}"
	echo "#---"

	# Remove files
	rm -R "$POSTGRES_DIR"
	rm -R "$UPLOAD_DIR"

	# Update RUN_MODE
	RUN_MODE="${RUN_MODE:6}"
fi

#
# Build the dev-to container
# Exits on failure
#
echo "#---"
echo "# Building dev-to $RUN_MODE docker container (yay!) ... "
echo "# If this is your first time running this build step, go grab a coffee - it may take a long while"
echo "# Alternatively, some paper swords with chairs : https://xkcd.com/303/"
echo "#---"

if [ "$RUN_MODE" = "DEV" ]
then
	# Build the DEV mode container
	docker build --target alpine-ruby-node -t dev-to:dev . || exit $?
else
	# Build the DEMO mode container
	docker build -t dev-to:demo . || exit $?
fi

#
# Deploy postgresql container
#
echo "#---"
echo "# Deploying postgresql container"
echo "#"
echo "# POSTGRES_DIR : $POSTGRES_DIR"
echo "#---"
mkdir -p "$POSTGRES_DIR"
docker run -d --name dev-to-postgres -e POSTGRES_PASSWORD=devto -e POSTGRES_USER=devto -e POSTGRES_DB=PracticalDeveloper_development -v "$POSTGRES_DIR:/var/lib/postgresql/data" postgres:10.7-alpine

#
# Wait for postgresql server
# this waits up to ~6*10 seconds
#
echo "#---"
echo "# Waiting for postgres server (this commonly takes 10 ~ 60 seconds) ... "
echo -n "# ."
RETRIES=12
until docker exec dev-to-postgres psql -U devto -d PracticalDeveloper_development -c "select 1" > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
	echo -n "."
	sleep 5
  RETRIES=$((RETRIES - 1))
done
echo ""
echo "# Wait completed, moving on ... "
echo "#---"

#
# Deploy dev-to container
#
echo "#---"
echo "# Deploying dev-to container"
echo "#"
echo "# RUN_MODE   : $RUN_MODE"
echo "# REPO_DIR   : $REPO_DIR"
echo "# UPLOAD_DIR : $UPLOAD_DIR"
echo "#---"
mkdir -p "$UPLOAD_DIR"

#
# in DEV mode - lets run in interactive mode
#
if [ "$RUN_MODE" = "DEV" ]
then
	docker run -it -p 3000:3000 \
	--name dev-to-app \
	--link dev-to-postgres:db \
	-v "$REPO_DIR:/usr/src/app" \
	-e RUN_MODE="DEV" \
	-e DATABASE_URL=postgresql://devto:devto@db:5432/PracticalDeveloper_development \
	--entrypoint "/usr/src/app/docker-entrypoint.sh" \
	$DEVTO_DOCKER_FLAGS \
	dev-to:dev

	# End of dev mode
	exit 0;
fi

#
# in DEMO mode - lets run it in the background
#
docker run -d -p 3000:3000 \
--name dev-to-app \
--link dev-to-postgres:db \
-v "$UPLOAD_DIR:/usr/src/app/public/uploads/" \
-e RUN_MODE="DEMO" \
-e DATABASE_URL=postgresql://devto:devto@db:5432/PracticalDeveloper_development \
$DEVTO_DOCKER_FLAGS \
dev-to:demo

#
# Wait for dev.to server
# this waits up to ~20*30 seconds
#
echo "#---"
echo "# Waiting for dev.to server... "
echo "#"
echo "# this commonly takes 2 ~ 10 minutes, basically, a very long time .... =[ "

# Side note, looped to give 4 set of distinct lines
# especially if long wait times occur (to make it more manageable)
for i in 1 2 3 4
do
	RETRIES=30
	echo -n "# ."
	until docker exec dev-to-app curl -I --max-time 5 -f http://localhost:3000/ > /dev/null 2>&1 || [ $RETRIES -eq 0 ]; do
		echo -n "."
		sleep 5
    RETRIES=$((RETRIES - 1))
	done
	echo ""
done

echo "# Wait completed, moving on ... "
echo "#---"

#
# Dumping out docker info
#
echo "#---"
echo "# Displaying relevant docker information"
echo "#---"
DOCKER_INFO=$(docker ps)
echo "$DOCKER_INFO" | head -1
echo "$DOCKER_INFO" | grep dev-to-

#
# Finishing message
#
echo "#---"
echo "# Container deployed on address ( http://localhost:3000 )"
echo "# "
echo "# Time to dev.to(gether)"
echo "#---"
