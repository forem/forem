#!/bin/bash

#
# Lets setup the alias file
#
echo "" > ~/.bashrc
echo "alias devto-setup='cd /usr/src/app/ && gem install bundler && bundle install --jobs 20 --retry 5 && yarn install && yarn check --integrity && bin/setup'" >> ~/.bashrc
echo "alias devto-migrate='cd /usr/src/app/ && bin/rake db:migrate'" >> ~/.bashrc
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
	echo "> Welcome to the dev.to, DEVELOPMENT container, for convinence your repository"
	echo "> has been mounted onto '/usr/src/app/', and port 3000 should be forwarded to your host machine"
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
bin/setup

#
# DB migration
# (@TODO - someone please confirm if i should use bin/rake or bin/rails for this step, and also if I can safely call htis on every startup)
#
bin/rake db:migrate

#
# Execute rails server on port 3000
#
bundle exec rails server -b 0.0.0.0 -p 3000
