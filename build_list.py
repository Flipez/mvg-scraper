import json

with open('stations.json') as file:
  stations = json.load(file)

  f = open('scape_stations.txt', 'w')
  for station in stations:
    if 'UBAHN' in station['products'] and 'München' in station['place']:
      f.write(station['id'] + '\n')
  f.close()
