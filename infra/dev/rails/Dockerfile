FROM ruby:2.5.1

WORKDIR /usr/src/app

RUN apt-get update -y && apt-get install apt-transport-https

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update  -y  && \
    apt-get install -y yarn

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs

COPY Gemfile Gemfile.lock yarn.lock ./

RUN yarn

ENV RAILS_ENV development

RUN bundle check || bundle install --jobs 20 --retry 5

ENTRYPOINT ["bundle", "exec"]

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "8080"]