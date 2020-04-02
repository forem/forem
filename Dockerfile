FROM ruby:2.6.5-alpine3.10

#------------------------------------------------------------------------------
#
# Install Project dependencies
#
#------------------------------------------------------------------------------
RUN apk update -qq && apk add git nodejs postgresql-client ruby-dev build-base \
  less libxml2-dev libxslt-dev pcre-dev libffi-dev postgresql-dev tzdata imagemagick

#------------------------------------------------------------------------------
#
# Install required bundler version
#
#------------------------------------------------------------------------------
RUN gem install bundler:2.0.2

#------------------------------------------------------------------------------
#
# Install Yarn
#
#------------------------------------------------------------------------------
ENV PATH=/root/.yarn/bin:$PATH
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community \
  yarn

#------------------------------------------------------------------------------
#
# Define working directory
#
#------------------------------------------------------------------------------
WORKDIR /usr/src/app

#------------------------------------------------------------------------------
#
# Copy Gemfile and run bundle install
#
#------------------------------------------------------------------------------
COPY ./.ruby-version .
COPY ./Gemfile ./Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5

#------------------------------------------------------------------------------
#
# Copy Package.json and yarn.lock
#
#------------------------------------------------------------------------------
COPY ./package.json ./yarn.lock ./

#------------------------------------------------------------------------------
#
# Install packages
#
#------------------------------------------------------------------------------
RUN yarn install && yarn check --integrity

# timeout extension required to ensure
# system work properly on first time load
ENV RACK_TIMEOUT_WAIT_TIMEOUT=10000 \
  RACK_TIMEOUT_SERVICE_TIMEOUT=10000 \
  STATEMENT_TIMEOUT=10000

# Run mode configuration between dev / demo
# for entrypoint script behaviour
ENV	RUN_MODE="demo"

# Database URL configuration - with user/pass
ENV	DATABASE_URL="postgresql://devto:devto@db:5432/PracticalDeveloper_development"

# DB setup / migrate script triggers on boot
ENV DB_SETUP="false" \
  DB_MIGRATE="false"

#
# Let's setup the public uploads folder volume
#
RUN mkdir -p /usr/src/app/public/uploads
VOLUME /usr/src/app/public/uploads

# Entrypoint and command to start the server
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

COPY . .
