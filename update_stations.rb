require 'json'
require 'typhoeus'

###
# Endpoint provides a list with all station that are served my the MVG
STATIONS_URL = 'https://www.mvg.de/.rest/zdm/stations'
response = Typhoeus.get(STATIONS_URL)

###
# Store response to use as local cache for future operations
File.write('stations.json', response.body)

stations = JSON.parse(response.body)
station_ids = []

stations.each do |station|
  ###
  # Include only stations that serve the subway and are located in Munich (including 'Garching b. München')
  if station["products"].include?('UBAHN') && station['place'].include?('München')
    station_ids << station['id']
  end
end

###
# Write file to use by the scraper as source for stations to scrape
# If no subway station suddenly appears this should be 96 stations
File.write("scrape_stations.txt", station_ids.join("\n"))
