require 'date'
require 'fileutils'
require 'typhoeus'
require 'json'
require 'logger'
require 'prometheus/client'

require './logo'

prometheus = Prometheus::Client.registry

http_requests = Prometheus::Client::Counter.new(
  :http_requests,
  docstring: 'number of mvg scaper requests'
)
response_codes = Prometheus::Client::Counter.new(
  :response_codes,
  docstring: 'number of response codes',
  labels: [:code]
)
response_size = Prometheus::Client::Histogram.new(
  :response_size,
  docstring: 'size of responses',
  buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.1, factor: 1.2, count: 30)
)
response_time = Prometheus::Client::Histogram.new(
  :response_time,
  docstring: 'time of responses',
  buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.1, factor: 1.2, count: 27)
)

prometheus.register(http_requests)
prometheus.register(response_codes)
prometheus.register(response_size)
prometheus.register(response_time)

Encoding.default_external = Encoding::UTF_8
Ethon.logger = Logger.new(nil)
logger = Logger.new(STDOUT)
logger.formatter = proc do |severity, datetime, progname, msg|
  JSON.dump(timestamp: "#{datetime.to_s}", message: msg) + "\n"
end

DEPARTURE_URL = "https://www.mvg.de/api/fib/v2/departure"

DATA_DIR        = ENV['MVG_DATA_DIR']      || './data'
MAX_CONCURRENCY = ENV['MVG_CONCURRENCY']   || 2
SAMPLE_SIZE     = ENV['MVG_STATION_RANGE'] || 0

stations = File.readlines('scrape_stations.txt', chomp: true)


def request_station(station, logger, thread_id)
  now = DateTime.now()
  today = now.strftime("%Y%m%d")
  timestamp = now.strftime("%s")

  FileUtils.mkdir_p "#{DATA_DIR}/#{today}"
  folder = "#{DATA_DIR}/#{today}/#{station}/"
  FileUtils.mkdir_p folder

  params = { globalId: station }
  headers = {"User-Agent": "rmueller/thesis"}

  request = Typhoeus::Request.new(DEPARTURE_URL, headers: headers, params: params)

  request.on_complete do |res|
    logger.info({thread: thread_id, code: res.code, length: res.body.size, station: station, total_time: res.total_time })
    json = {
      appconnect_time:    res.appconnect_time,
      connect_time:       res.connect_time,
      headers:            res.headers,
      httpauth_avail:     res.httpauth_avail,
      namelookup_time:    res.namelookup_time,
      pretransfer_time:   res.pretransfer_time,
      primary_ip:         res.primary_ip,
      redirect_count:     res.redirect_count,
      redirect_url:       res.redirect_url,
      request_params:     params,
      request_header:     headers,
      request_size:       res.request_size,
      request_url:        DEPARTURE_URL,
      response_code:      res.response_code,
      return_code:        res.return_code,
      return_message:     res.return_message,
      size_download:      res.size_download,
      size_upload:        res.size_upload,
      starttransfer_time: res.starttransfer_time,
      total_time:         res.total_time
    }
    File.write("#{folder}#{timestamp}_meta.json", JSON.pretty_generate(json))
    File.write("#{folder}#{timestamp}_body.json", res.body)
  end

  request
end

queue = Queue.new

stations = stations[0..SAMPLE_SIZE.to_i]
stations.each do |station|
  queue << station
end

threads = []

puts logo(MAX_CONCURRENCY, stations.size)

MAX_CONCURRENCY.times do |thread_id|
  threads << Thread.new do
    loop do
      station = queue.pop
      r = request_station(station, logger, thread_id)


      res = r.run

      http_requests.increment
      response_codes.increment(labels: {code: res.response_code})
      response_size.observe(res.body.size/1000)
      response_time.observe(res.total_time)

      wait_time = ((( 60.0 * MAX_CONCURRENCY ) / stations.size) - res.total_time)

      p "thread #{thread_id} request took #{res.total_time} for station #{station}, wait #{wait_time}"
      sleep([wait_time, 0].max)
      queue << station
    end
  end
end
