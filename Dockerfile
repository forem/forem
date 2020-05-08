FROM quay.io/devto/ruby:2.7.1

USER root

RUN curl -sL https://dl.yarnpkg.com/rpm/yarn.repo -o /etc/yum.repos.d/yarn.repo && \
    dnf install -y bash git nodejs postgresql ruby-devel less libxml2-devel libxslt-devel \
    pcre-devel libffi-devel postgresql-devel tzdata ImageMagick libcurl \
    libcurl-devel yarn

ENV BUNDLER_VERSION=2.1.4
RUN gem install bundler:${BUNDLER_VERSION}

RUN mkdir -p /opt/apps/devto
WORKDIR /opt/apps/devto

COPY ./.ruby-version .
COPY ./Gemfile ./Gemfile.lock ./
RUN bundle check || bundle install --jobs 20 --retry 5

COPY ./package.json ./yarn.lock ./.yarnrc ./
COPY ./.yarn ./.yarn

RUN yarn install

RUN mkdir -p ./public/uploads
VOLUME ./public/uploads

COPY . .

ENTRYPOINT ["./scripts/entrypoint-rails.sh"]
