#!/bin/bash

#
# Lets setup the alias file
# @TODO - add as scripts instead within /bin? - this will help auto fill?
#
echo "" > ~/.bashrc
echo "alias devto-setup='cd /usr/src/app/ && gem install bundler && bundle install --jobs 20 --retry 5 && yarn install && yarn check --integrity && bin/setup'" >> ~/.bashrc
echo "alias devto-migrate='cd /usr/src/app/ && bin/rails db:migrate'" >> ~/.bashrc
echo "alias devto-start='cd /usr/src/app/ && bundle exec rails server -b 0.0.0.0 -p 3000'" >> ~/.bashrc

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
	echo "> In addition the following alias commands has been preconfigured to get you up and running quickly"
	echo "> "
	echo ">    devto-setup   : Does the gem/yarn dependency installation, along with database setup"
	echo ">    devto-migrate : Calls the database migration script"
	echo ">    devto-start   : Start the rails application server on port 3000"
	echo "> "
	echo "> Finally to exit this container bash terminal (and stop the container), use the command 'exit'"
	echo ">---"

	# Lets startup bash for the user to interact with
	/bin/bash
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
echo ">---"
echo "> [dev.to/docker-entrypoint.sh] Starting the rails servers - whheee!"
echo ">---"
bundle exec rails server -b 0.0.0.0 -p 3000
