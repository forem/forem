FROM gitpod/workspace-postgres

# Install Ruby
ENV RUBY_VERSION=3.0.2

# Install the GitHub CLI
RUN brew install gh

# Taken from https://www.gitpod.io/docs/languages/ruby
RUN echo "rvm_gems_path=/home/gitpod/.rvm" > ~/.rvmrc
RUN bash -lc "rvm install ruby-$RUBY_VERSION && rvm use ruby-$RUBY_VERSION --default"
RUN echo "rvm_gems_path=/workspace/.rvm" > ~/.rvmrc

# Install Node and Yarn
ENV NODE_VERSION=14.17.6
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
