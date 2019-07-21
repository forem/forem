#####################################################
#
# Alpine container with
# (this is used in DEV mode)
#
# + ruby:2.6.3
# + node:8.15.0
# + yarn:1.12.3
#
#####################################################
FROM node:8.15.1-alpine AS alpine-ruby-node

#------------------------------------------------------------------------------------------
#
# Ruby installation, taken from the official ruby alpine dockerfile
# see : https://github.com/docker-library/ruby/blob/9ae0943fa2935b3a13c72ae7d6afa2439145d7fa/2.6/alpine3.9/Dockerfile
#
#------------------------------------------------------------------------------------------

RUN apk add --no-cache \
  gmp-dev

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
  echo 'install: --no-document'; \
  echo 'update: --no-document'; \
  } >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.6
ENV RUBY_VERSION 2.6.3
ENV RUBY_DOWNLOAD_SHA256 11a83f85c03d3f0fc9b8a9b6cad1b2674f26c5aaa43ba858d4b0fcc2b54171e1

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
# readline-dev vs libedit-dev: https://bugs.ruby-lang.org/issues/11869 and https://github.com/docker-library/ruby/issues/75
RUN set -ex \
  \
  && apk add --no-cache --virtual .ruby-builddeps \
  autoconf \
  bison \
  bzip2 \
  bzip2-dev \
  ca-certificates \
  coreutils \
  dpkg-dev dpkg \
  gcc \
  gdbm-dev \
  glib-dev \
  libc-dev \
  libffi-dev \
  libxml2-dev \
  libxslt-dev \
  linux-headers \
  make \
  ncurses-dev \
  openssl \
  openssl-dev \
  procps \
  readline-dev \
  ruby \
  tar \
  xz \
  yaml-dev \
  zlib-dev \
  \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR%-rc}/ruby-$RUBY_VERSION.tar.xz" \
  && echo "$RUBY_DOWNLOAD_SHA256 *ruby.tar.xz" | sha256sum -c - \
  \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  \
  && cd /usr/src/ruby \
  \
  # https://github.com/docker-library/ruby/issues/196
  # https://bugs.ruby-lang.org/issues/14387#note-13 (patch source)
  # https://bugs.ruby-lang.org/issues/14387#note-16 ("Therefore ncopa's patch looks good for me in general." -- only breaks glibc which doesn't matter here)
  && wget -O 'thread-stack-fix.patch' 'https://bugs.ruby-lang.org/attachments/download/7081/0001-thread_pthread.c-make-get_main_stack-portable-on-lin.patch' \
  && echo '3ab628a51d92fdf0d2b5835e93564857aea73e0c1de00313864a94a6255cb645 *thread-stack-fix.patch' | sha256sum -c - \
  && patch -p1 -i thread-stack-fix.patch \
  && rm thread-stack-fix.patch \
  \
  # hack in "ENABLE_PATH_CHECK" disabling to suppress:
  #   warning: Insecure world writable dir
  && { \
  echo '#define ENABLE_PATH_CHECK 0'; \
  echo; \
  cat file.c; \
  } > file.c.new \
  && mv file.c.new file.c \
  \
  && autoconf \
  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  # the configure script does not detect isnan/isinf as macros
  && export ac_cv_func_isnan=yes ac_cv_func_isinf=yes \
  && ./configure \
  --build="$gnuArch" \
  --disable-install-doc \
  --enable-shared \
  && make -j "$(nproc)" \
  && make install \
  \
  && runDeps="$( \
  scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
  | tr ',' '\n' \
  | sort -u \
  | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && apk add --no-network --virtual .ruby-rundeps $runDeps \
  bzip2 \
  ca-certificates \
  libffi-dev \
  procps \
  yaml-dev \
  zlib-dev \
  && apk del --no-network .ruby-builddeps \
  && cd / \
  && rm -r /usr/src/ruby \
  # rough smoke test
  && ruby --version && gem --version && bundle --version

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
  BUNDLE_SILENCE_ROOT_WARNING=1 \
  BUNDLE_APP_CONFIG="$GEM_HOME"
# path recommendation: https://github.com/bundler/bundler/pull/6469#issuecomment-383235438
ENV PATH $GEM_HOME/bin:$BUNDLE_PATH/gems/bin:$PATH
# adjust permissions of a few directories for running "gem install" as an arbitrary user
RUN mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"
# (BUNDLE_PATH = GEM_HOME, no need to mkdir/chown both)

#------------------------------------------------------------------------------------------
#
# End of ruby installation
#
#------------------------------------------------------------------------------------------

# Install alpine equivalent for "build-essential"
#
# and other dependencies required by dev.to various
# ruby dependencies (postgresql-dev, tzdata)
RUN apk add --no-cache alpine-sdk postgresql-dev tzdata

# Im installing bash, as im a bash addict (not that great with sh)
RUN apk add bash

# Let's setup the rails directory
# (@TODO - consider a production version?)
WORKDIR /usr/src/app
ENV RAILS_ENV development

#####################################################
#
# Let's prepare the dev.to source code files
# WITHOUT docker related files
#
# This allow us to modify the docker
# entrypoint / run file without recompiling
# the entire application
# (especially when creating this build script =| )
#
# (@TODO - improve and review ignore to blacklist unneeded items)
#
#####################################################

#
# Prepare the source code and remove any unneeded files
#
FROM alpine-ruby-node AS source-code-repo

# The workdir
WORKDIR /usr/src/app
# Copy source code
COPY ./ /usr/src/app/
# remove docker related files
RUN rm Dockerfile && rm docker-*

#
# Does the source code build
#
FROM alpine-ruby-node AS source-code-build

# Copy over files
COPY --from=source-code-repo /usr/src/app/ /usr/src/app/

# Run the various installer
RUN gem install bundler
RUN bundle install --jobs 20 --retry 5
RUN yarn install && yarn check --integrity

#####################################################
#
# Let's build the DEMO dev.to image
#
#####################################################
FROM alpine-ruby-node

# Copy over the application code (without docker related files)
COPY --from=source-code-build /usr/src/app/ /usr/src/app/

# Copy over docker related files
COPY Dockerfile [(docker-)]* /usr/src/app/

#
# Execution environment variables
#

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
ENV DB_SETUP="true" \
  DB_MIGRATE="true"

#
# Let's setup the public uploads folder volume
#
RUN mkdir -p /usr/src/app/public/uploads
VOLUME /usr/src/app/public/uploads

# Entrypoint and command to start the server
ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]
CMD []
