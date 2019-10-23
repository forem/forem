#!/bin/ash

#
# Lets ensure we are in the correct workspace
#
cd /usr/src/app/

#
# Lets handle "DEV" RUN_MODE
#
if [[ "$RUN_MODE" = "DEV" ]]
then
	echo ">---"
	echo "> [dev.to/docker-entrypoint.sh] DEV mode"
	echo "> "
	echo "> Welcome to the dev.to, DEVELOPMENT container, for convenience your repository"
	echo "> should be mounted onto '/usr/src/app/', and port 3000 should be forwarded to your host machine"
	echo "> "
	echo "> Everything should be ready, here are some example commands you can run:"
	echo "> "
	echo ">    initial setup : bin/setup"
	echo ">    migrate       : bundle exec rails db:migrate"
	echo ">    server        : bundle exec rails server -b 0.0.0.0"
	echo "> "
	echo "> Finally to exit this container shell (and stop the container), use the command 'exit'"
	echo ">---"

	# Lets startup ash for the user to interact with
	/bin/ash -l
	exit $?;
fi

#
# Lets handle "DEMO" RUN_MODE
#
echo ">---"
echo "> [dev.to/docker-entrypoint.sh] DEMO mode"
echo "> "
echo "> Time to rock & roll"
echo ">---"

#
# DB setup
# note this will fail (intentionally), if DB was previously setup
#
if [[ "$DB_SETUP" == "true" ]]
then
	echo ">---"
	echo "> [dev.to/docker-entrypoint.sh] Performing DB_SETUP : you can skip this step by setting DB_SETUP=false"
	echo ">---"
	bin/setup
fi

#
# DB migration script
#
if [[ "$DB_MIGRATE" == "true" ]]
then
	echo ">---"
	echo "> [dev.to/docker-entrypoint.sh] Performing DB_MIGRATE : you can skip this step by setting DB_MIGRATE=false"
	echo ">---"
	bin/rails db:migrate
fi

#
# Execute rails server on port 3000
#
if [[ "$APP_SERVER" == "true" ]]
then
	echo ">---"
	echo "> [dev.to/docker-entrypoint.sh] Starting the rails servers - whheee!"
	echo ">---"
	rm -f tmp/pids/server.pid
	bundle exec rails server -b 0.0.0.0 -p 3000
fi
