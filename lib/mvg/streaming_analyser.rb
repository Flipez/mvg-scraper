# frozen_string_literal: true

require 'zstds'
require 'minitar'
require 'json'
require 'sqlite3'

module MVG
  ###
  # Provides streaming access to contend of compressed data archive
  class StreamingAnalyser
    attr_reader :files

    def initialize(files)
      @files = files
    end

    def stream(&block)
      files.each do |file|
        ZSTDS::Stream::Reader.open file do |reader|
          Minitar::Reader.open reader do |tar|
            tar.each_entry(&block)
          end
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
        db = SQLite3::Database.new "export.db"

        db.execute <<-SQL
          create table responses_meta (
            id text,
            appconnect_time real,
            connect_time real,
            headers_date text,
            headers_x_frame_options text,
            headers_strict_transport_security text,
            headers_pragma text,
            headers_cache_control text,
            headers_expires text,
            headers_content_type text,
            headers_server text,
            headers_set_cookie text,
            httpauth_avail int,
            namelookup_time real,
            pretransfer_time real,
            primary_ip text,
            redirect_count int,
            redirect_url text,
            request_params_global_id text,
            request_header_user_agent text,
            request_size int,
            request_url text,
            response_code int,
            return_code text,
            return_message text,
            size_download int,
            size_upload int,
            starttransfer_time real,
            total_time real
          );
        SQL

        db.execute('BEGIN TRANSACTION')
        sql = db.prepare(%q(
          INSERT INTO responses_meta (
            id,
            appconnect_time,
            connect_time,
            headers_date,
            headers_x_frame_options,
            headers_strict_transport_security,
            headers_pragma,
            headers_cache_control,
            headers_expires,
            headers_content_type,
            headers_server,
            headers_set_cookie,
            httpauth_avail,
            namelookup_time,
            pretransfer_time,
            primary_ip,
            redirect_count,
            redirect_url,
            request_params_global_id,
            request_header_user_agent,
            request_size,
            request_url,
            response_code,
            return_code,
            return_message,
            size_download,
            size_upload,
            starttransfer_time,
            total_time
          )
          VALUES
          (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ))

      files.each do |file|
        puts file
        stream do |entry|
          if entry.name.end_with? 'meta.json'
            date, station_id, timestamp = entry.name.match(/(\d+)\/(.+)\/(\d+)_/).captures
            content = JSON.parse(entry.read)

            sql.execute([
              "#{date}_#{station_id}_#{timestamp}",
              content['appconnect_time'],
              content['connect_time'],
              content['headers']['date'],
              content['headers']['x-frame-options'],
              content['headers']['strict-transport-security'],
              content['headers']['pragma'],
              content['headers']['cache-control'],
              content['headers']['expires'],
              content['headers']['content-type'],
              content['headers']['server'],
              content['headers']['set-cookie'],
              content['httpauth_avail'],
              content['namelookup_time'],
              content['pretransfer_time'],
              content['primary_ip'],
              content['redirect_count'],
              content['redirect_url'],
              content['request_params']['globalId'],
              content['request_header']['User-Agent'],
              content['request_size'],
              content['request_url'],
              content['response_code'],
              content['return_code'],
              content['return_message'],
              content['size_download'],
              content['size_upload'],
              content['starttransfer_time'],
              content['total_time']
            ])
          end
        end

        db.execute('COMMIT')
      end
    end
  end
end
