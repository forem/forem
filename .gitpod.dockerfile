FROM gitpod/workspace-postgres

# Install the GitHub CLI
RUN brew install gh

# Install Ruby
ENV RUBY_VERSION=3.1.4
RUN printf "rvm_gems_path=/home/gitpod/.rvm\n" > ~/.rvmrc \
    && bash -lc "rvm reinstall $RUBY_VERSION && \
                 rvm use $RUBY_VERSION --default" \
    && printf "rvm_gems_path=/workspace/.rvm" > ~/.rvmrc \
    && printf "{ rvm use \$(rvm current); } >/dev/null 2>&1\n" >> "$HOME/.bashrc.d/70-ruby"

# Install Node and Yarn
ENV NODE_VERSION=16.13.1
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
