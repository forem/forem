FROM ruby:3.0.2-buster
MAINTAINER CodeandoMexico

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV RAILS_ENV production
ENV NODE_ENV production
ENV PORT 3000
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true
ENV BUNDLE_WITHOUT=development:test
ENV BUILD_PACKAGES build-essential libpq-dev ca-certificates libreadline-dev libxml2-dev \
                   libxslt1-dev imagemagick nodejs git

RUN mkdir /app
WORKDIR /app

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update \
    && apt-get install -y --fix-missing --no-install-recommends $BUILD_PACKAGES \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

COPY .ruby-version /app/
COPY Gemfile /app/
COPY Gemfile.lock /app/

ENV BUNDLER_VERSION=2.2.22 BUNDLE_SILENCE_ROOT_WARNING=true BUNDLE_SILENCE_DEPRECATIONS=true
RUN gem install -N bundler:"${BUNDLER_VERSION}"

RUN bundle install

COPY package.json /app/
COPY yarn.lock /app/

RUN npm install -g yarn
RUN yarn install

COPY . /app

RUN bundle exec rake assets:precompile

EXPOSE 80
