# frozen_string_literal: true

require 'rack'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

require_relative 'lib/mvg'

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

MVG::Scraper.new.run

run ->(_) { [200, { 'content-type' => 'text/html' }, ['OK']] }
