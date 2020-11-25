
@@ -0,0 +1,7 @@
steps:
  - command: ./scripts/build_containers.sh
    plugins:
      - docker-login#v2.0.1:
          username: QUAY_LOGIN_USER
          password-env: QUAY_LOGIN_PASSWORD
          server: QUAY_LOGIN_SERVER
 8  .github/CODEOWNERS 
@@ -17,8 +17,14 @@
/lib/sidekiq/                                       @forem/sre
/spec/rails_helper.rb                               @forem/sre
/spec/support/                                      @forem/sre
.buildkite/                                         @forem/systems @forem/sre
.travis.yml                                         @forem/sre
Containerfile                                       @forem/systems
docker-compose.yml                                  @forem/systems
Dockerfile                                          @forem/systems
Gemfile                                             @forem/sre    @forem/oss
Gemfile.lock                                        @forem/sre    @forem/oss
package.json                                        @forem/oss    @nickytonline
podman-compose.yml                                  @forem/systems
scripts/                                            @forem/systems
yarn.lock                                           @forem/oss    @nickytonline
.travis.yml                                         @forem/sre
 136  Containerfile 
@@ -1,49 +1,42 @@
FROM quay.io/forem/ruby:2.7.2
FROM quay.io/forem/ruby:2.7.2 as builder

USER root

RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf install -y bash curl git ImageMagick iproute jemalloc less libcurl libcurl-devel \
                   libffi-devel libxml2-devel libxslt-devel nodejs pcre-devel \
                   postgresql postgresql-devel ruby-devel tzdata yarn \
                   && dnf -y clean all \
                   && rm -rf /var/cache/yum

ENV APP_USER=forem
ENV APP_UID=1000
ENV APP_GID=1000
ENV APP_HOME=/opt/apps/forem
ENV LD_PRELOAD=/usr/lib64/libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}"
RUN groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser -u "${APP_UID}" -g "${APP_GID}" -d "${APP_HOME}" "${APP_USER}"

ENV BUNDLER_VERSION=2.1.4
    dnf install --setopt install_weak_deps=false -y \
    ImageMagick iproute jemalloc less libcurl libcurl-devel \
    libffi-devel libxml2-devel libxslt-devel nodejs pcre-devel \
    postgresql postgresql-devel tzdata yarn && \
    dnf -y clean all && \
    rm -rf /var/cache/yum

ENV BUNDLER_VERSION=2.1.4 BUNDLE_SILENCE_ROOT_WARNING=1
RUN gem install bundler:"${BUNDLER_VERSION}"
ENV GEM_HOME=/opt/apps/bundle
ENV BUNDLE_SILENCE_ROOT_WARNING=1 BUNDLE_APP_CONFIG="${GEM_HOME}"
ENV PATH "${GEM_HOME}"/bin:$PATH
RUN mkdir -p "${GEM_HOME}" && chown "${APP_UID}":"${APP_GID}" "${GEM_HOME}"

ENV APP_USER=forem APP_UID=1000 APP_GID=1000 APP_HOME=/opt/apps/forem \
    LD_PRELOAD=/usr/lib64/libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}" && \
    groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser -u "${APP_UID}" -g "${APP_GID}" -d "${APP_HOME}" "${APP_USER}"

ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/"${DOCKERIZE_VERSION}"/dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && rm dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz
    && rm dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && chown root:root /usr/local/bin/dockerize

WORKDIR "${APP_HOME}"

# Comment out running as the forem user due to this issue with podman-compose:
# https://github.com/containers/podman-compose/issues/166
# USER "${APP_USER}"

COPY ./.ruby-version "${APP_HOME}"/
COPY ./Gemfile ./Gemfile.lock "${APP_HOME}"/
COPY ./vendor/cache "${APP_HOME}"/vendor/cache

# Fixes https://github.com/sass/sassc-ruby/issues/146
RUN bundle config build.sassc --disable-march-tune-native

RUN bundle check || bundle install --jobs 20 --retry 5
RUN bundle config build.sassc --disable-march-tune-native && \
    bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

RUN mkdir -p "${APP_HOME}"/public/{assets,images,packs,podcasts,uploads}

@@ -55,8 +48,91 @@ RUN echo $(date -u +'%Y-%m-%dT%H:%M:%SZ') >> "${APP_HOME}"/FOREM_BUILD_DATE && \
    echo $(git rev-parse --short HEAD) >> "${APP_HOME}"/FOREM_BUILD_SHA && \
    rm -rf "${APP_HOME}"/.git/

RUN rm -rf node_modules app/assets vendor/assets vendor/cache spec

## Production
FROM quay.io/forem/ruby:2.7.2 as production

USER root

RUN dnf install --setopt install_weak_deps=false -y bash curl ImageMagick \
                iproute jemalloc less libcurl \
                postgresql tzdata \
                && dnf -y clean all \
                && rm -rf /var/cache/yum

ENV BUNDLER_VERSION=2.1.4 BUNDLE_SILENCE_ROOT_WARNING=1
RUN gem install bundler:"${BUNDLER_VERSION}"

ENV APP_USER=forem APP_UID=1000 APP_GID=1000 APP_HOME=/opt/apps/forem \
    LD_PRELOAD=/usr/lib64/libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}" && \
    groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser -u "${APP_UID}" -g "${APP_GID}" -d "${APP_HOME}" "${APP_USER}"

COPY --from=builder --chown="${APP_USER}":"${APP_USER}" ${APP_HOME} ${APP_HOME}

USER "${APP_USER}"
WORKDIR "${APP_HOME}"

VOLUME "${APP_HOME}"/public/

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

## Testing
FROM builder AS testing

USER root

RUN dnf install --setopt install_weak_deps=false -y \
    chromium-headless chromedriver && \
    yum clean all && \
    rm -rf /var/cache/yum

COPY --chown="${APP_USER}":"${APP_USER}" ./app/assets "${APP_HOME}"/app/assets
COPY --chown="${APP_USER}":"${APP_USER}" ./vendor/cache "${APP_HOME}"/vendor/cache
COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN chown "${APP_USER}":"${APP_USER}" -R "${APP_HOME}"

USER "${APP_USER}"

RUN bundle config build.sassc --disable-march-tune-native && \
    bundle config set deployment 'false' && \
    bundle config --delete without 'development test' && \
    bundle install --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

RUN yarn install --frozen-lockfile && RAILS_ENV=test NODE_ENV=test bundle exec rails webpacker:compile

ENTRYPOINT ["./scripts/entrypoint-dev.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

## Development
FROM builder AS development

COPY --chown="${APP_USER}":"${APP_USER}" ./app/assets "${APP_HOME}"/app/assets
COPY --chown="${APP_USER}":"${APP_USER}" ./vendor/cache "${APP_HOME}"/vendor/cache
COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN chown "${APP_USER}":"${APP_USER}" -R "${APP_HOME}"

USER "${APP_USER}"

RUN bundle config build.sassc --disable-march-tune-native && \
    bundle config set deployment 'false' && \
    bundle config --delete without 'development test' && \
    bundle install --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

ENTRYPOINT ["./scripts/entrypoint-dev.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
