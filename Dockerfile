#####################################################
#
# Alpine container with 
# (this is used in DEV mode)
# 
# + ruby:2.6.1
# + node:8.15.0
# + yarn:1.12.3
#
#####################################################
FROM ruby:2.6.1-alpine3.9 AS alpine-ruby-node

# Original nodejs install code taken from nodejs alpine repo
# see : https://github.com/nodejs/docker-node/blob/master/8/alpine/Dockerfile

# Install node
ENV NODE_VERSION 8.15.0
RUN addgroup -g 1000 node \
    && adduser -u 1000 -G node -s /bin/sh -D node \
    && apk add --no-cache \
        libstdc++ \
    && apk add --no-cache --virtual .build-deps \
        binutils-gold \
        curl \
        g++ \
        gcc \
        gnupg \
        libgcc \
        linux-headers \
        make \
        python \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
    && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
    && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
    && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
    && tar -xf "node-v$NODE_VERSION.tar.xz" \
    && cd "node-v$NODE_VERSION" \
    && ./configure \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && make install \
    && apk del .build-deps \
    && cd .. \
    && rm -Rf "node-v$NODE_VERSION" \
    && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

# Install yarn
ENV YARN_VERSION 1.12.3
RUN apk add --no-cache --virtual .build-deps-yarn curl gnupg tar \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && apk del .build-deps-yarn

# Install alpine eqivalent for "build-essential"
#
# and other dependencies required by dev.to various
# ruby dependencies (postgresql-dev, tzdata)
RUN apk add --no-cache alpine-sdk postgresql-dev tzdata

# Im installing bash, as im a bash addict (not that great with sh)
RUN apk add bash

# Lets setup the rails directory
# (@TODO - consider a production version?)
WORKDIR /usr/src/app
ENV RAILS_ENV development

#####################################################
#
# Lets prepare the dev.to source code files
# WITHOUT docker related files
#
# This allow us to modify the docker
# entrypoint / run file without recompiling
# the entire application 
# (especially when creating this buidl script =| )
#
# (@TODO - improve and review ignore to blacklist unneded items)
#
#####################################################
FROM alpine-ruby-node AS source-code-container

# The workdir
WORKDIR /usr/src/app
# Copy source code
COPY ./ /usr/src/app/
# remove docker related files
RUN rm Dockerfile && rm docker-*

#####################################################
#
# Lets build the DEMO dev.to image
#
#####################################################
FROM alpine-ruby-node

# Copy over the application code (without docker related files)
COPY --from=source-code-container /usr/src/app/ /usr/src/app/

# Reruns installer
RUN gem install bundler
RUN bundle install --jobs 20 --retry 5
RUN yarn install && yarn check --integrity

# Copy over docker related files
COPY Dockerfile [(docker-)]* /usr/src/app/

#
# Execution environment variables
#
# timeout extension requried to ensure 
# system work properly on first time load
#
ENV RACK_TIMEOUT_WAIT_TIMEOUT=10000 \ 
	RACK_TIMEOUT_SERVICE_TIMEOUT=10000 \ 
	STATEMENT_TIMEOUT=10000 \
	RUN_MODE="demo" \
	DATABASE_URL="postgresql://devto:devto@db:5432/PracticalDeveloper_development"

#
# Lets setup the public uploads folder volume
#
RUN mkdir -p /usr/src/app/public/uploads
VOLUME /usr/src/app/public/uploads

# Entrypoint and command to start the server
ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]
CMD []
