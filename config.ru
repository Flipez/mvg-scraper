require 'rack'
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

require './scrape'

use Rack::Deflater
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

run ->(_) { [200, { 'content-type' => 'text/html' }, ['OK']] }
