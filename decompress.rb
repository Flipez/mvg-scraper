require 'zstds'
require 'minitar'

ZSTDS::Stream::Reader.open "20240217.tar.zst" do |reader|
  Minitar::Reader.open reader do |tar|
    tar.each_entry do |entry|
      puts entry.name
      entry.read
    end
  end
end