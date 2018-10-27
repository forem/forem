FROM ruby:2.5.3

# Make nodejs and yarn as dependencies
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Install dependencies and perform clean-up
RUN apt-get update -qq && apt-get install -y \
   build-essential \
   nodejs \
   yarn \
 && apt-get -q clean \
 && rm -rf /var/lib/apt/lists

WORKDIR /usr/src/app
ENV RAILS_ENV development

# Installing Ruby dependencies
COPY Gemfile* ./
RUN gem install bundler
RUN bundle install --jobs 20 --retry 5

# Install JavaScript dependencies
COPY yarn.lock ./
ENV YARN_INTEGRITY_ENABLED "false"
RUN yarn install && yarn check --integrity

ENTRYPOINT ["bundle", "exec"]

CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3000"]
