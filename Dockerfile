FROM starefossen/ruby-node:2-8-stretch

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock yarn.lock ./

RUN yarn install && yarn check --integrity

ENV RAILS_ENV development

ENV YARN_INTEGRITY_ENABLED "false"

RUN bundle install --jobs 20 --retry 5

ENTRYPOINT ["bundle", "exec"]

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
