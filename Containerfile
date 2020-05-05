FROM devto/ruby:2.7.1

RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf install -y git nodejs postgresql ruby-devel less libxml2-devel libxslt-devel \
    pcre-devel libffi-devel postgresql-devel tzdata ImageMagick libcurl \
    libcurl-devel yarn
RUN gem install bundler:2.1.4

WORKDIR /opt/apps/devto

COPY ./.ruby-version .
COPY ./Gemfile ./Gemfile.lock ./
RUN bundle install --jobs 20 --retry 5

COPY ./package.json ./yarn.lock ./.yarnrc ./
COPY ./.yarn ./.yarn

RUN yarn install

ENV RACK_TIMEOUT_WAIT_TIMEOUT=10000 \
  RACK_TIMEOUT_SERVICE_TIMEOUT=10000 \
  STATEMENT_TIMEOUT=10000

ENV	RUN_MODE="demo"

ENV	DATABASE_URL="postgresql://devto:devto@db:5432/PracticalDeveloper_development"

ENV DB_SETUP="false" \
  DB_MIGRATE="false"

ENV REDIS_URL="redis://redis:6379" \
  REDIS_SESSIONS_URL="redis://redis:6379"

RUN mkdir -p /opt/apps/devto/public/uploads
VOLUME /opt/apps/devto/public/uploads

COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh

COPY . .