FROM quay.io/forem/ruby:2.7.1

ARG RAILS_ENV

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
ENV APP_HOME=/opt/apps/forem/
ENV LD_PRELOAD=/usr/lib64/libjemalloc.so.2
RUN mkdir -p ${APP_HOME} && chown "${APP_UID}":"${APP_GID}" "${APP_HOME}"
RUN groupadd -g "${APP_GID}" "${APP_USER}" && \
    adduser -u "${APP_UID}" -g "${APP_GID}" -d "${APP_HOME}" "${APP_USER}"

ENV BUNDLER_VERSION=2.1.4
RUN gem install bundler:"${BUNDLER_VERSION}"
ENV GEM_HOME=/opt/apps/bundle/
ENV BUNDLE_SILENCE_ROOT_WARNING=1 BUNDLE_APP_CONFIG="${GEM_HOME}"
ENV PATH "${GEM_HOME}"/bin:$PATH
RUN mkdir -p "${GEM_HOME}" && chown "${APP_UID}":"${APP_GID}" "${GEM_HOME}"

ENV DOCKERIZE_VERSION=v0.6.1
RUN wget https://github.com/jwilder/dockerize/releases/download/"${DOCKERIZE_VERSION}"/dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz \
    && rm dockerize-linux-amd64-"${DOCKERIZE_VERSION}".tar.gz

WORKDIR "${APP_HOME}"

# Comment out running as the forem user due to this issue with podman-compose:
# https://github.com/containers/podman-compose/issues/166
# USER "${APP_USER}"

COPY ./.ruby-version "${APP_HOME}"
COPY ./Gemfile ./Gemfile.lock "${APP_HOME}"
COPY ./vendor/cache "${APP_HOME}"/vendor/cache

RUN bundle check || bundle install --jobs 20 --retry 5
RUN echo $(date --utc +%FT%T%Z) > /opt/apps/bundle/bundle_finished

COPY ./package.json ./yarn.lock ./.yarnrc "${APP_HOME}"
COPY ./.yarn "${APP_HOME}"/.yarn
RUN yarn install --frozen-lockfile

RUN mkdir -p "${APP_HOME}"/public/{assets,images,packs,podcasts,uploads}

COPY . "${APP_HOME}"

VOLUME "${APP_HOME}"/public/

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails","server","-b","0.0.0.0","-p","3000"]
