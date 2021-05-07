FROM gitpod/workspace-postgres

# Install Ruby
ENV RUBY_VERSION=2.7.2
RUN rm /home/gitpod/.rvmrc && touch /home/gitpod/.rvmrc && echo "rvm_gems_path=/home/gitpod/.rvm" > /home/gitpod/.rvmrc
RUN bash -lc "rvm install ruby-$RUBY_VERSION && rvm use ruby-$RUBY_VERSION --default"

# Install Node and Yarn
ENV NODE_VERSION=14.14.0
RUN bash -c ". .nvm/nvm.sh && \
        nvm install ${NODE_VERSION} && \
        nvm alias default ${NODE_VERSION} && \
        npm install -g yarn"
ENV PATH=/home/gitpod/.nvm/versions/node/v${NODE_VERSION}/bin:$PATH

# Install Redis.
RUN sudo apt-get update \
  && sudo apt-get install -y \
  redis-server \
  && sudo rm -rf /var/lib/apt/lists/*
