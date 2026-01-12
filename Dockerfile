# Use the official Ruby image from Docker Hub
# https://hub.docker.com/_/ruby

# [START cloudrun_rails_base_image]
# Pinning the OS to buster because the nodejs install script is buster-specific.
# Be sure to update the nodejs install command if the base image OS is updated.
FROM ruby:3.4
# [END cloudrun_rails_base_image]

# Install Node.js (updated method for Debian Bookworm)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# Install Yarn
RUN npm install -g yarn

# Install Google Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Define path for Google Chrome
ENV BROWSER_PATH /usr/bin/google-chrome-stable

WORKDIR /app

# Application dependencies
COPY Gemfile Gemfile.lock ./
 
RUN gem install bundler && \
	bundle lock --add-platform ruby && \
	bundle lock --add-platform x86_64-linux && \
    # bundle config set --local deployment 'true' && \
    # bundle config set --local without 'development test' && \
    bundle install


# Copy application code to the container image
COPY . /app

ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
# Redirect Rails log to STDOUT for Cloud Run to capture
ENV RAILS_LOG_TO_STDOUT=true
# [START cloudrun_rails_dockerfile_key]
ARG MASTER_KEY
ENV RAILS_MASTER_KEY=${MASTER_KEY}
# [END cloudrun_rails_dockerfile_key]

# Database configuration
ARG PRODUCTION_DB_NAME
ARG PRODUCTION_DB_USERNAME
ARG CLOUD_SQL_CONNECTION_NAME
ARG SERVICE_NAME
ENV PRODUCTION_DB_NAME=${PRODUCTION_DB_NAME}
ENV PRODUCTION_DB_USERNAME=${PRODUCTION_DB_USERNAME}
ENV CLOUD_SQL_CONNECTION_NAME=${CLOUD_SQL_CONNECTION_NAME}
ENV SERVICE_NAME=${SERVICE_NAME}

# pre-compile Rails assets with master key
RUN bundle exec rake assets:precompile

EXPOSE 8080
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "8080"]