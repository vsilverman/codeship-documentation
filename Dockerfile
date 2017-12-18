FROM ruby:2.4.3-slim

ENV CACHE_BUST=2017-09-12 \
    DEBIAN_DISTRIBUTION="jessie" \
    DEBIAN_FRONTEND="noninteractive" \
    NODE_VERSION="8.x"

# Basic project configuration
WORKDIR /docs
EXPOSE 4000

# System dependencies
RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  apt-transport-https \
  curl && \
  curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
  echo "deb https://deb.nodesource.com/node_${NODE_VERSION} ${DEBIAN_DISTRIBUTION} main" > /etc/apt/sources.list.d/nodesource.list && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian stable main" > /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
  build-essential \
  graphicsmagick \
  libssl1.0.0 \
  libyaml-0-2 \
  nodejs \
  yarn && \
  ln -s "$(which nodejs)" /usr/local/bin/node && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/*

# NPM based dependencies
COPY package.json yarn.lock ./
RUN \
  yarn install --production --frozen-lockfile --non-interactive && \
  ln -s /docs/node_modules/gulp/bin/gulp.js /usr/local/bin/gulp

# Ruby based dependencies
COPY Gemfile Gemfile.lock ./
RUN \
  echo "gem: --no-rdoc --no-ri" >> "${HOME}/.gemrc" && \
  bundle install --jobs 20 --retry 5 --without development

# Copy the complete site
COPY . ./

# Serve the site
CMD ["bundle", "exec", "jekyll", "serve", "-H", "0.0.0.0", "--incremental"]
