FROM gitpod/workspace-postgres

# Install Ruby
COPY .ruby-version /tmp
RUN bash -lc "rvm install ruby-$(cat /tmp/.ruby-version)" \
 && rm -f /tmp/*
