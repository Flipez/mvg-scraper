# frozen_string_literal: true

require 'zstds'
require 'minitar'
require 'json'

module MVG
  ###
  # Provides streaming access to contend of compressed data archive
  class StreamingAnalyser
    attr_reader :file

    def initialize(file)
      @file = file
    end

    def stream(&block)
      ZSTDS::Stream::Reader.open file do |reader|
        Minitar::Reader.open reader do |tar|
          tar.each_entry(&block)
        end
      end
    end

    def requests_per_station
      stations = {}

      stream do |entry|
        if entry.name.end_with? 'meta.json'
          content = JSON.parse(entry.read)
          station = content['request_params']['globalId']
          stations[station] = stations[station].to_i + 1
        end
      end

      stations.each do |k, v|
        puts "#{k}\t: #{v}"
      end

      nil
    end
  end
end
