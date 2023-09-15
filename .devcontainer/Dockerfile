FROM ghcr.io/forem/ruby:3.1.4@sha256:d072fde5b0bb0f1374e308f7fcf1283e379e2a28a61f6e56df87b25a7dfdd5bf

RUN apt update && \
    apt install -y \
        build-essential \
        libpq-dev \
      && \
  apt clean

SHELL ["/bin/bash", "-l", "-c"]

RUN gem install dip
