import requests
import datetime
import asyncio
import aiohttp
import logging
import daiquiri
import time
import numpy as np
from pathlib import Path

DEPARTURE_URL = "https://www.mvg.de/api/fib/v2/departure"


with open('scape_stations.txt') as file:
  stations = file.read().split()

now = datetime.datetime.now()
today = now.strftime("%Y%m%d")
minutes = now.hour * 60 + now.minute
Path(f"./data/{today}/").mkdir(parents=True, exist_ok=True)

## Setup logging
daiquiri.setup(level=logging.INFO, outputs=(
    daiquiri.output.File("./data/{}/requests.log".format(today),
                         formatter=daiquiri.formatter.JSON_FORMATTER),
    ))
logger = daiquiri.getLogger(__name__, subsystem="requests")


async def get(station, session):
    try:
        async with session.get(url=DEPARTURE_URL, params={'globalId': station}) as response:
            resp = await response.read()

            folder = "./data/{}/{}/".format(today,station)
            Path(folder).mkdir(parents=True, exist_ok=True)
            
            with open('{}{}.json'.format(folder, minutes), 'w') as file:
              r = requests.get(DEPARTURE_URL, params = {'globalId': station})
              file.write(r.text)

            logger.info({"station": station,
                         "status": response.status,
                         "time": time.time(),
                         "length": len(resp)})
    except Exception as e:
        print(e)
        print("Unable to get url {} due to {}.".format(station, e.__class__))


async def main(chunks):
    for stations in chunks:
      async with aiohttp.ClientSession() as session:
          ret = await asyncio.gather(*[get(station, session) for station in stations])
      print("Finalized all. Return is a list of len {} outputs.".format(len(ret)))

arr = np.array(stations)
chunks = np.array_split(arr, 10)

asyncio.run(main(chunks))

