FROM quay.io/forem/ruby:2.7.2 as builder

USER root

RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf install --setopt install_weak_deps=false -y \
    ImageMagick iproute jemalloc less libcurl libcurl-devel \
    libffi-devel libxml2-devel libxslt-devel nodejs pcre-devel \
    postgresql postgresql-devel tzdata yarn && \
    dnf -y clean all && \
    rm -rf /var/cache/yum

ENV BUNDLER_VERSION=2.2.15 BUNDLE_SILENCE_ROOT_WARNING=true BUNDLE_SILENCE_DEPRECATIONS=true
RUN gem install -N bundler:"${BUNDLER_VERSION}"

ENV APP_USER=forem APP_UID=1000 APP_GID=1000 APP_HOME=/opt/apps/forem \
    LD_PRELOAD=/usr/lib64/libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}" && \
    groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser -u "${APP_UID}" -g "${APP_GID}" -d "${APP_HOME}" "${APP_USER}"

ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/"${DOCKERIZE_VERSION}"/dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && rm dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && chown root:root /usr/local/bin/dockerize

WORKDIR "${APP_HOME}"

COPY ./.ruby-version "${APP_HOME}"/
COPY ./Gemfile ./Gemfile.lock "${APP_HOME}"/
COPY ./vendor/cache "${APP_HOME}"/vendor/cache

RUN bundle config --local build.sassc --disable-march-tune-native && \
    BUNDLE_WITHOUT="development:test" bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

COPY . "${APP_HOME}"

RUN mkdir -p "${APP_HOME}"/public/{assets,images,packs,podcasts,uploads}

RUN RAILS_ENV=production NODE_ENV=production bundle exec rake assets:precompile

RUN echo $(date -u +'%Y-%m-%dT%H:%M:%SZ') >> "${APP_HOME}"/FOREM_BUILD_DATE && \
    echo $(git rev-parse --short HEAD) >> "${APP_HOME}"/FOREM_BUILD_SHA && \
    rm -rf "${APP_HOME}"/.git/

RUN rm -rf node_modules vendor/assets spec

## Production
FROM quay.io/forem/ruby:2.7.2 as production

USER root

RUN dnf install --setopt install_weak_deps=false -y bash curl ImageMagick \
                iproute jemalloc less libcurl \
                postgresql tzdata nodejs \
                && dnf -y clean all \
                && rm -rf /var/cache/yum

ENV BUNDLER_VERSION=2.2.15 BUNDLE_SILENCE_ROOT_WARNING=1
RUN gem install -N bundler:"${BUNDLER_VERSION}"

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

COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN chown "${APP_USER}":"${APP_USER}" -R "${APP_HOME}"

USER "${APP_USER}"

RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle config --delete without && \
    bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

## Development
FROM builder AS development

COPY --chown="${APP_USER}":"${APP_USER}" ./spec "${APP_HOME}"/spec
COPY --from=builder /usr/local/bin/dockerize /usr/local/bin/dockerize

RUN chown "${APP_USER}":"${APP_USER}" -R "${APP_HOME}"

USER "${APP_USER}"

RUN bundle config --local build.sassc --disable-march-tune-native && \
    bundle config --delete without && \
    bundle install --deployment --jobs 4 --retry 5 && \
    find "${APP_HOME}"/vendor/bundle -name "*.c" -delete && \
    find "${APP_HOME}"/vendor/bundle -name "*.o" -delete

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
