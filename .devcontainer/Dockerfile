FROM mcr.microsoft.com/devcontainers/universal:2-linux

SHELL ["/bin/bash", "-l", "-c"]
# TODO
# COPY ../.ruby-version /tmp/.ruby-version
RUN RUBY_VERSION=3.1.4 && \
    rvm install $RUBY_VERSION && \
    rvm use $RUBY_VERSION --default && \
    gem install dip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
