FROM fedora

LABEL maintainer="Forem Systems Engineering <systems@forem.com>"

USER root

RUN dnf upgrade --setopt install_weak_deps=false -y && dnf install bash && dnf -y clean all && rm -rf /var/cache/yum && \
    dnf upgrade -y && dnf install autoconf bison curl git gzip make patch tar wget xz file gcc-c++ bzip2-devel gdbm-devel gmp-devel glib2-devel libcurl-devel libxml2-devel libxslt-devel libffi-devel ncurses-devel openssl-devel readline-devel redhat-rpm-config --setopt install_weak_deps=false -y && dnf install ruby ruby-devel ruby-irb ruby-libs rubygems rubygems-devel -y && dnf -y clean all && rm -rf /var/cache/yum

ENV BUNDLE_SILENCE_ROOT_WARNING=1
ENV RUBY_MAJOR=3.0
ENV RUBY_VERSION=3.0.2

CMD [ "/usr/bin/irb" ]