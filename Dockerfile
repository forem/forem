FROM ruby:2.6.0

ARG PG_VERSION=9.6

RUN curl -sSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
  && echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' $PG_VERSION > /etc/apt/sources.list.d/pgdg.list

# Make nodejs and yarn as dependencies
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install dependencies and perform clean-up
RUN apt-get update -qq && apt-get install -y \
   build-essential \
   less \
   vim \
   postgresql-client-$PG_VERSION \
   nodejs \
   yarn \
 && apt-get -q clean \
 && rm -rf /var/lib/apt/lists

ENV RAILS_ENV development

ENV LANG=C.UTF-8 \
  GEM_HOME=/bundle \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
  BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH $BUNDLE_BIN:$PATH

ADD https://github.com/krallin/tini/releases/download/v0.18.0/tini /tini
RUN chmod +x /tini

WORKDIR /app
ENTRYPOINT ["/tini", "--"]
