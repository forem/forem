#!/bin/sh

# # Start the postgresq server
# if [ "$CONTAINER_TYPE" -eq "FULL" ]
# then
# 	rc-service postgres start
# fi

#
# Lets ensure we are in the correct workspace
#
cd /usr/src/app/

/bin/bash

# #
# # DB setup 
# # note this will fail (intentionally), if DB was previously setup
# #
# bin/setup

# #
# # DB migration
# #
# bin/rails db:migrate

# #
# # Execute rails server on port 3000
# #
# bundle exec rails server -b 0.0.0.0 -p 3000

# # /bin/bash

# CHANGE SOMETHING