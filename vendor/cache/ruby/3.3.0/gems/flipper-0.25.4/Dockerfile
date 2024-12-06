FROM ruby:3.0

RUN apt-get update && apt-get install -y \
  # build-essential \

  # for postgres
  # libpq-dev \
  # postgresql-client-9.4 \

  # for nokogiri
  # libxml2-dev \
  # libxslt1-dev \

  # for a JS runtime
  # imagemagick \
  # ghostscript \

  # debug tools
  vim

ENV APP_HOME /srv/app

ENV BUNDLE_GEMFILE=$APP_HOME/Gemfile \
    BUNDLE_JOBS=8 \
    BUNDLE_PATH=/bundle_cache

WORKDIR $APP_HOME
