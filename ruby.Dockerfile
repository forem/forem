FROM fedora:35 as base

USER root

RUN dnf upgrade --setopt install_weak_deps=false -y && \
    dnf -y clean all && \
    rm -rf /var/cache/yum

CMD [ "bash" ]

FROM base

ARG RUBY_MAJOR=3.0
ARG RUBY_VERSION=3.0.2

ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV RUBY_MAJOR=${RUBY_MAJOR}
ENV RUBY_VERSION=${RUBY_VERSION}

RUN dnf upgrade -y && \
    dnf install \
        autoconf \
        bison \
        curl \
        git \
        gzip \
        make \
        patch \
        tar \
        wget \
        xz \
        file \
        gcc-c++ \
        bzip2-devel \
        gdbm-devel \
        gmp-devel \
        glib2-devel \
        libcurl-devel \
        libxml2-devel \
        libxslt-devel \
        libffi-devel \
        ncurses-devel \
        openssl-devel \
        readline-devel \
        redhat-rpm-config \
        --setopt install_weak_deps=false -y && \
    dnf install \
        ruby-${RUBY_VERSION} \
        ruby-devel-${RUBY_VERSION} \
        ruby-irb \
        ruby-libs-${RUBY_VERSION} \
        rubygems \
        rubygems-devel -y && \
    dnf -y clean all && \
    rm -rf /var/cache/yum

CMD [ "/usr/bin/irb" ]
