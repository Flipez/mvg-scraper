# frozen_string_literal: true

require 'prometheus/client'

module MVG
  ###
  # Handles prometheus client metrics
  class Metrics
    attr_reader :prometheus, :http_requests, :response_codes, :response_size, :response_time

    def initialize
      @prometheus = Prometheus::Client.registry

      @http_requests = Prometheus::Client::Counter.new(
        :http_requests,
        docstring: 'number of mvg scaper requests'
      )
      @response_codes = Prometheus::Client::Counter.new(
        :response_codes,
        docstring: 'number of response codes',
        labels: [:code]
      )
      @response_size = Prometheus::Client::Histogram.new(
        :response_size,
        docstring: 'size of responses',
        buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.1, factor: 1.2, count: 30)
      )
      @response_time = Prometheus::Client::Histogram.new(
        :response_time,
        docstring: 'time of responses',
        buckets: Prometheus::Client::Histogram.exponential_buckets(start: 0.1, factor: 1.2, count: 27)
      )

      prometheus.register(http_requests)
      prometheus.register(response_codes)
      prometheus.register(response_size)
      prometheus.register(response_time)
    end
  end
end
