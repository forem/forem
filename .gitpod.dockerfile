FROM gitpod/workspace-postgres
# The below variable is to be modified to trigger a Dockerfile rebuild (this is in YYYY-MM-DD format)
ENV IMAGE_BUILD_DATE=2019-11-3

# Install Ruby
COPY .ruby-version /tmp
RUN bash -lc "rvm install ruby-$(cat /tmp/.ruby-version)" \
 && rm -f /tmp/*
