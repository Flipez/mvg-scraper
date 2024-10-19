# frozen_string_literal: true


module MVG
  ###
  # Provides command line interface
  class Cli < Thor
    desc 'version', 'display the scraper version'
    def version
      puts("MVG Scraper version #{MVG::VERSION}")
    end

    desc 'update-stations', 'updates to local station file'
    def update_stations
      updater = MVG::StationUpdater.new
      updater.update!
    end
  end
end
