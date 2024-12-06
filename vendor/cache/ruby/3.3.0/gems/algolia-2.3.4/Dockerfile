FROM ruby:2.6.3

RUN gem install bundler

WORKDIR /app
COPY . /app/
RUN bundle install
