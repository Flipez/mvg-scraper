# frozen_string_literal: true

require 'date'
require 'fileutils'
require 'typhoeus'
require 'json'

require_relative 'logging'
require_relative 'metrics'
require_relative 'logo'

module MVG
  ###
  # Provides the main scraper which handles the request and scheduling
  class Scraper
    attr_accessor :threads
    attr_reader :departure_url, :data_dir, :logger, :metrics, :max_concurrency, :sample_size, :stations_file,
                :stations, :queue, :user_agent, :interval

    def initialize
      @departure_url = 'https://www.mvg.de/api/fib/v2/departure'

      @logger = MVG::Logging.new.logger
      @metrics = MVG::Metrics.new

      @data_dir        = ENV['MVG_DATA_DIR']      || './data'
      @max_concurrency = ENV['MVG_CONCURRENCY']   || 2
      @interval        = ENV['MVG_INTERVAL']      || 60.0

      @sample_size     = ENV['MVG_STATION_RANGE'] || 0
      @stations_file   = ENV['MVG_STATIONS_FILE'] || 'scrape_stations.txt'
      @stations = File.readlines(stations_file, chomp: true)[0..sample_size.to_i]

      @user_agent = ENV['MVG_USER_AGENT']

      @threads = []
      @queue   = Queue.new
    end

    def request_station(station)
      now = DateTime.now
      today = now.strftime('%Y%m%d')
      timestamp = now.strftime('%s')

      FileUtils.mkdir_p "#{data_dir}/#{today}"
      folder = "#{data_dir}/#{today}/#{station}/"
      FileUtils.mkdir_p folder

      params = { globalId: station }
      headers = user_agent ? { "User-Agent": user_agent } : {}

      request = Typhoeus::Request.new(departure_url, headers: headers, params: params)

      request.on_complete do |res|
        json = {
          appconnect_time: res.appconnect_time,
          connect_time: res.connect_time,
          headers: res.headers,
          httpauth_avail: res.httpauth_avail,
          namelookup_time: res.namelookup_time,
          pretransfer_time: res.pretransfer_time,
          primary_ip: res.primary_ip,
          redirect_count: res.redirect_count,
          redirect_url: res.redirect_url,
          request_params: params,
          request_header: headers,
          request_size: res.request_size,
          request_url: departure_url,
          response_code: res.response_code,
          return_code: res.return_code,
          return_message: res.return_message,
          size_download: res.size_download,
          size_upload: res.size_upload,
          starttransfer_time: res.starttransfer_time,
          total_time: res.total_time
        }
        File.write("#{folder}#{timestamp}_meta.json", JSON.pretty_generate(json))
        File.write("#{folder}#{timestamp}_body.json", res.body)
      end

      request
    end

    def prefill_queue
      stations.each do |station|
        queue << station
      end
    end

    def run
      prefill_queue
      MVG::Logo.print(max_concurrency, stations.size)

      max_concurrency.times do |thread_id|
        threads << Thread.new do
          loop do
            station = queue.pop
            r = request_station(station)

            res = r.run

            metrics.http_requests.increment
            metrics.response_codes.increment(labels: { code: res.response_code })
            metrics.response_size.observe(res.body.size / 1000)
            metrics.response_time.observe(res.total_time)

            wait_time = (((interval.to_f * max_concurrency) / stations.size) - res.total_time)

            logger.info({ thread: thread_id, code: res.code, length: res.body.size, station: station,
                          total_time: res.total_time, wait_time: wait_time })

            sleep([wait_time, 0].max)
            queue << station
          end
        end
      end
    end
  end
end
