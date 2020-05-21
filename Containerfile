FROM quay.io/devto/ruby:2.7.1

USER root

RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf install -y bash git ImageMagick iproute less libcurl libcurl-devel \
                   libffi-devel libxml2-devel libxslt-devel nodejs pcre-devel \
                   postgresql postgresql-devel ruby-devel tzdata yarn

ENV APP_USER=devto
ENV APP_UID=1000
ENV APP_GID=1000
ENV APP_HOME=/opt/apps/devto/
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

# As soon as this:
# https://github.com/containers/libpod/issues/6153
# issue is fixed for Linux users we can uncomment the line below so we are not
# running the app as the root user. :toot:
# USER "${APP_USER}"

COPY ./.ruby-version "${APP_HOME}"
COPY ./Gemfile ./Gemfile.lock "${APP_HOME}"
RUN bundle check || bundle install --jobs 20 --retry 5

COPY ./package.json ./yarn.lock ./.yarnrc "${APP_HOME}"
COPY ./.yarn "${APP_HOME}"/.yarn
RUN yarn install

RUN mkdir -p "${APP_HOME}"/public/{uploads,images,podcasts}

COPY . "${APP_HOME}"

ENTRYPOINT ["./scripts/entrypoint.sh"]

CMD ["bundle", "exec", "rails","server","-b","0.0.0.0","-p","3000"]
