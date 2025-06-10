# frozen_string_literal: true

require 'json'
require 'typhoeus'

module MVG
  ###
  # Updates the local station file used for scraping
  class StationUpdater
    attr_reader :stations_url, :stations_file

    def initialize
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
      station_ids = stations.filter_map do |station|
        station['id'] if station['id'].start_with?('de') &&
             !station['tariffZones'].empty? &&
             station['products'].any? { |product| %w[UBAHN TRAM SBAHN].include?(product) }
      end

      ###
      # Write file to use by the scraper as source for stations to scrape
      # If no subway station suddenly appears this should be 96 stations
      File.write(stations_file, station_ids.join("\n"))
    end
  end
end
