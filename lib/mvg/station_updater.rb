# frozen_string_literal: true

require 'json'
require 'typhoeus'

module MVG
  ###
  # Updates the local station file used for scraping
  class StationUpdater
    attr_reader :stations_url, :stations_file

    def intitialize
      @stations_url  = 'https://www.mvg.de/.rest/zdm/stations'
      @stations_file = ENV['MVG_STATIONS_FILE'] || 'scrape_stations.txt'
    end

    def update!
      ###
      # Endpoint provides a list with all station that are served my the MVG
      response = Typhoeus.get(stations_url)

      ###
      # Store response to use as local cache for future operations
      File.write('stations.json', response.body)

      stations = JSON.parse(response.body)
      station_ids = []

      stations.each do |station|
        ###
        # Include only stations that serve the subway and are located in Munich (including 'Garching b. München')
        station_ids << station['id'] if station['products'].include?('UBAHN') && station['place'].include?('München')
      end

      ###
      # Write file to use by the scraper as source for stations to scrape
      # If no subway station suddenly appears this should be 96 stations
      File.write(stations_file, station_ids.join("\n"))
    end
  end
end
