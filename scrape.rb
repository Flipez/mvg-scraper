require 'date'
require 'fileutils'
require 'typhoeus'
require 'json'
require 'logger'

Encoding.default_external = Encoding::UTF_8
Ethon.logger = Logger.new(nil)
logger = Logger.new(STDOUT)
logger.formatter = proc do |severity, datetime, progname, msg|
  JSON.dump(timestamp: "#{datetime.to_s}", message: msg) + "\n"
end

DEPARTURE_URL = "https://www.mvg.de/api/fib/v2/departure"

stations = File.readlines('scape_stations.txt', chomp: true)

now = DateTime.now()
today = now.strftime("%Y%m%d")
minutes = now.hour * 60 + now.minute

FileUtils.mkdir_p "./data/#{today}"

hydra = Typhoeus::Hydra.new(max_concurrency: 2)

# TODO: remove
stations = stations.shuffle[0..1]

stations.each do |station|
  folder = "./data/#{today}/#{station}/"
  FileUtils.mkdir_p folder

  request = Typhoeus::Request.new(
    DEPARTURE_URL,
    #headers: {"User-Agent": "rmueller/thesis-scaper"},
    params: { globalId: station })

  request.on_complete do |res|
    logger.info({code: res.code, length: res.body.size, station: station, total_time: res.total_time })
    if res.success?
      json = {
        appconnect_time:    res.appconnect_time,
        connect_time:       res.connect_time,
        headers:            res.headers,
        httpauth_avail:     res.httpauth_avail,
        namelookup_time:    res.namelookup_time,
        pretransfer_time:   res.pretransfer_time,
        primary_ip:         res.primary_ip,
        redirect_count:     res.redirect_count,
        redirect_url:       res.redirect_url,
        request_size:       res.request_size,
        response_code:      res.response_code,
        return_code:        res.return_code,
        return_message:     res.return_message,
        size_download:      res.size_download,
        size_upload:        res.size_upload,
        starttransfer_time: res.starttransfer_time,
        total_time:         res.total_time,
        body:               JSON.parse(res.body),
      }
      File.write("#{folder}#{minutes}.json", JSON.pretty_generate(json))
    end
  end

  hydra.queue request
end

hydra.run
hydra.run