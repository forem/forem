FROM ruby:2.5.1


EXPOSE 3000

RUN apt-get update && apt-get install apt-transport-https -y && \

#Installing nodejs
   curl -sL https://deb.nodesource.com/setup_8.x | bash - &&  apt-get install -y nodejs && \

#Installing yarnpkg
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |  apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" |  tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install yarn -y 

#RUN bundle install && bin/yarn && bin/setup
WORKDIR /usr/src/app
COPY . .
RUN bundle install --jobs 20 --retry 5 && ./bin/yarn 

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

CMD /bin/bash entrypoint.sh

