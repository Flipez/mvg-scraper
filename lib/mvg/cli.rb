# frozen_string_literal: true

require 'sqlite3'

module MVG
  ###
  # Provides command line interface
  class Cli < Thor
    desc 'version', 'display the stan version'
    def version
      puts("MVG Scraper version #{MVG::VERSION}")
    end

    desc 'update-stations', 'updates to local station file'
    def update_stations
      updater = MVG::StationUpdater.new
      updater.update!
    end

    desc 'export FILE', 'exports the given compressed file into sqlite'
    def export(file)
      streamer = MVG::StreamingAnalyser.new(file)

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

      streamer.stream do |entry|
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
