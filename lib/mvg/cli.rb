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

    desc 'export FILES', 'exports the given compressed file into sqlite'
    def export(*files)
      analyser = MVG::StreamingAnalyser.new(files)
      analyser.sqlite_export
    end
  end
end
