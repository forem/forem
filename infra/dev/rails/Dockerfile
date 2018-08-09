FROM node:8.11.3-slim as node_build

COPY yarn.lock .

RUN yarn

FROM ruby:2.5.1 as ruby_build

WORKDIR /usr/src/app

RUN apt-get update -y && apt-get install apt-transport-https


COPY Gemfile Gemfile.lock ./

COPY --from=node_build /node_modules /usr/src/app

ENV RAILS_ENV development

RUN bundle check || bundle install --jobs 20 --retry 5

ENTRYPOINT ["bundle", "exec"]

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "8080"]