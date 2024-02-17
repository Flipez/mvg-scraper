require 'zstds'
require 'minitar'
require 'json'

stations = {}

ZSTDS::Stream::Reader.open '20240217.tar.zst' do |reader|
  Minitar::Reader.open reader do |tar|
    tar.each_entry do |entry|
      if entry.name.end_with? 'meta.json'
        content = JSON.parse(entry.read)
        stations[content['request_params']['globalId']] = stations[content['request_params']['globalId']].to_i + 1
      end
    end
  end
end

stations.sort_by { |k, _v| k }.each do |k, v|
  puts "#{k}\t: #{v}"
end
