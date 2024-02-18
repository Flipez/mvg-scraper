# frozen_string_literal: true

require 'zstds'
require 'minitar'
require 'json'
require 'sqlite3'

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

    def sqlite_export
      db = SQLite3::Database.new "#{file.split('.')[0]}.db"

      db.execute <<-SQL
        create table responses (
          station varchar(15),
          code int,
          size_download real,
          timestamp int
        );
      SQL

      db.execute('BEGIN TRANSACTION')
      sql = db.prepare('INSERT INTO responses (station, code, size_download, timestamp) VALUES (?, ?, ?, ?)')

      stream do |entry|
        if entry.name.end_with? 'meta.json'
          content = JSON.parse(entry.read)

          puts "#{content['request_params']['globalId']} at #{entry.name}"
          sql.execute([content['request_params']['globalId'],
                       content['return_code'],
                       content['size_download'],
                       entry.name.split('_')[0].to_i])
        end
      end
      db.execute('COMMIT')
    end
  end
end
