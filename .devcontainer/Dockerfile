FROM mcr.microsoft.com/devcontainers/ruby:3-bookworm

SHELL ["/bin/bash", "-l", "-c"]

RUN gem install dip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
