FROM gitpod/workspace-postgres

# Install Ruby
ENV RUBY_VERSION=2.7.1
RUN rm /home/gitpod/.rvmrc && touch /home/gitpod/.rvmrc && echo "rvm_gems_path=/home/gitpod/.rvm" > /home/gitpod/.rvmrc
RUN bash -lc "rvm install ruby-$RUBY_VERSION && rvm use ruby-$RUBY_VERSION --default"

# Install Node and Yarn
ENV NODE_VERSION=12.18.2
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

# Install Elasticsearch
ARG ES_REPO=https://artifacts.elastic.co/downloads/elasticsearch
ARG ES_ARCHIVE=elasticsearch-oss-7.5.2-linux-x86_64.tar.gz
RUN wget "${ES_REPO}/${ES_ARCHIVE}" \
  && wget "${ES_REPO}/${ES_ARCHIVE}.sha512" \
  && shasum -a 512 -c ${ES_ARCHIVE}.sha512 \
  && tar -xzf ${ES_ARCHIVE}
