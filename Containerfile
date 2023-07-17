FROM ghcr.io/forem/ruby:3.0.6@sha256:287260a9c729fcd4f7952c551f8320cfe484db9d1e3ac77986b175b959aba715 as base

FROM base as builder

# This is provided by BuildKit
ARG TARGETARCH

USER root

# pkg-config,
# libpixman-1-dev,
# libcairo2-dev,
# libpango1.0-dev
#
# are needed only on arm64: some nodejs dependency doesn't provide
# pre-built binaries for that arch, and so falls back to building
# from source, which then requires a few extra packages installed.
#
# Since we wipe out node_modules as part of this image after calling
# the bundler, we don't need these headers (or their sofile counterparts)
# in any of the other build stages.
RUN apt update && \
    apt install -y \
        build-essential \
        libcurl4-openssl-dev \
        libffi-dev \
        libxml2-dev \
        libxslt-dev \
        libpcre3-dev \
        libpq-dev \
        pkg-config \
        libpixman-1-dev \
        libcairo2-dev \
        libpango1.0-dev \
        && \
    apt clean

ENV BUNDLER_VERSION=2.2.22 \
    BUNDLE_SILENCE_ROOT_WARNING=true \
    BUNDLE_SILENCE_DEPRECATIONS=true

RUN gem install -N bundler:"${BUNDLER_VERSION}"

ENV APP_USER=forem APP_UID=1000 APP_GID=1000 APP_HOME=/opt/apps/forem \
    LD_PRELOAD=libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}" && \
    groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser --uid "${APP_UID}" --gid "${APP_GID}" --home "${APP_HOME}" "${APP_USER}"

ENV DOCKERIZE_VERSION=v0.7.0
RUN curl -fsSLO https://github.com/jwilder/dockerize/releases/download/"${DOCKERIZE_VERSION}"/dockerize-linux-${TARGETARCH}-"${DOCKERIZE_VERSION}".tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-${TARGETARCH}-"${DOCKERIZE_VERSION}".tar.gz \
    && rm dockerize-linux-${TARGETARCH}-"${DOCKERIZE_VERSION}".tar.gz \
    && chown root:root /usr/local/bin/dockerize

USER "${APP_USER}"
WORKDIR "${APP_HOME}"

COPY --chown=${APP_UID}:${APP_GID} ./.ruby-version "${APP_HOME}"/
COPY --chown=${APP_UID}:${APP_GID} ./Gemfile ./Gemfile.lock "${APP_HOME}"/
COPY --chown=${APP_UID}:${APP_GID} ./vendor/cache "${APP_HOME}"/vendor/cache

# Have to reset APP_CONFIG, which appears to be set by upstream images, to
# avoid permission errors in the development/test images (which run bundle
# as a user and require write access to the config file for setting things
# like BUNDLE_WITHOUT (a value that is cached by root here in this builder
# layer, see https://michaelheap.com/bundler-ignoring-bundle-without/))
ENV BUNDLE_APP_CONFIG="${APP_HOME}/.bundle"
RUN mkdir -p "${BUNDLE_APP_CONFIG}" && \
    touch "${BUNDLE_APP_CONFIG}/config" && \
    chown -R "${APP_UID}:${APP_GID}" "${BUNDLE_APP_CONFIG}" && \
    bundle config --local build.sassc --disable-march-tune-native && \
    bundle config --local without development:test && \
    BUNDLE_FROZEN=true bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

COPY --chown=${APP_UID}:${APP_GID} . "${APP_HOME}"

RUN mkdir -p "${APP_HOME}"/public/{assets,images,packs,podcasts,uploads}

# While it's relatively rare for bare metal builds to hit the default
# timeout, QEMU-based ones (as is the case with Docker BuildX for
# cross-compiling) quite often can. This increased timeout should help
# reduce false-negatives when building multiarch images.
RUN echo 'network-timeout 300000' >> ~/.yarnrc

# This is one giant step now because previously, removing node_modules to save
# layer space was done in a later step, which is invalid in at least some
# Docker storage drivers (resulting in Directory Not Empty errors).
RUN NODE_ENV=production yarn install && \
    RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile && \
    rm -rf node_modules

# This used to be calculated within the container build, but we then tried
# to rm -rf the .git that was copied in, which isn't valid (removing
# directories created in lower layers of an image isn't a thing (at least
# with the overlayfs drivers). Instead, we'll pass this in over CLI when
# building images (eg. in CI), but leave a default value for callers who don't
# override (perhaps docker-compose). This isn't perfect, but it'll do for now.
ARG VCS_REF=unspecified

RUN echo $(date -u +'%Y-%m-%dT%H:%M:%SZ') >> "${APP_HOME}"/FOREM_BUILD_DATE && \
    echo "${VCS_REF}" >> "${APP_HOME}"/FOREM_BUILD_SHA

## Production
FROM base as production

USER root

ENV BUNDLER_VERSION=2.2.22 BUNDLE_SILENCE_ROOT_WARNING=1
RUN gem install -N bundler:"${BUNDLER_VERSION}"

ENV APP_USER=forem APP_UID=1000 APP_GID=1000 APP_HOME=/opt/apps/forem \
    LD_PRELOAD=libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}" && \
    groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser --uid "${APP_UID}" --gid "${APP_GID}" --home "${APP_HOME}" "${APP_USER}"

COPY --from=builder --chown="${APP_USER}":"${APP_USER}" ${APP_HOME} ${APP_HOME}

USER "${APP_USER}"
WORKDIR "${APP_HOME}"

VOLUME "${APP_HOME}"/public/

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

## Testing
FROM builder AS testing

USER "${APP_USER}"

COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle config --delete without && \
    BUNDLE_FROZEN=true bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

## Development
FROM builder AS development

USER "${APP_USER}"

COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle config --delete without && \
    BUNDLE_FROZEN=true bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
