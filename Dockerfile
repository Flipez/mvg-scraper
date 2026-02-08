# Use Ruby 4.0.1 as base image
FROM ruby:4.0.1-slim

# Install system dependencies
# - build-essential, git: for building native gems
# - libcurl4-openssl-dev: for typhoeus gem
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /srv/mvg-scraper

# Copy gemspec and dependency files
COPY Gemfile Gemfile.lock mvg.gemspec ./
COPY lib/mvg/version.rb ./lib/mvg/

# Install Ruby dependencies
RUN bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Set environment variables (matching systemd service)
ENV MVG_STATION_RANGE=-1
ENV MVG_INTERVAL=360
ENV MVG_CONCURRENCY=1
ENV MVG_USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:139.0) Gecko/20100101 Firefox/139.0"

# Expose Puma port (default Rack port)
EXPOSE 9292

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9292/metrics || exit 1

# Run puma server
CMD ["puma"]
