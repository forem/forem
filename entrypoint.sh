#!/bin/bash

cat <<EOF > config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  # For details on connection pooling, see rails configuration guide
  # http://guides.rubyonrails.org/configuring.html#database-pooling
  pool: 5
  connect_timeout: 2
  checkout_timeout: 2
  adapter:  <%= ENV['DB_ADAPTER'] || 'postgresql' %>
  host:     <%= ENV['DB_HOST'] || 'postgres' %>
  username: <%= ENV['DB_USER'] || 'postgres' %>
  password: <%= ENV['DB_PASSWORD'] || 'mysecretpassword' %>
  variables:
      statement_timeout: <%= ENV['STATEMENT_TIMEOUT'] || 2500 %>
      
development:
  <<: *default
  database: <%= ENV['DB_DATABASE'] || 'PracticalDeveloper_development' %>

test:
  <<: *default
  database: <%= ENV['DB_DATABASE'] || 'PracticalDeveloper_test' %>

production:
  <<: *default
  database: <%= ENV['DB_DATABASE'] || 'PracticalDeveloper_production' %>
EOF

set_var() {
VAR_NAME=$1
VAR_VALUE=$2
sed -i "/:${VAR_NAME}/ s~default:.*~default: \"${VAR_VALUE}\"~" Envfile
}

VARS=$(cat Envfile | awk '/variable/{print $2}' | sed 's/[:|,]//g')
for v in $VARS ; do  [[ ${!v} ]] && set_var $v ${!v} ; done

if [[ -f setup.flag ]] ; then
  ./bin/rails server
else
  ./bin/setup && touch setup.flag
  ./bin/rails server
fi
