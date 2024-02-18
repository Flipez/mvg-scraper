# frozen_string_literal: true


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
      analyser = MVG::StreamingAnalyser.new(file)
      analyser.sqlite_export
    end
  end
end
