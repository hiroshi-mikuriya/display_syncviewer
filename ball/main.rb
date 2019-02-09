# frozen_string_literal: true

require 'httpclient'
require 'json'
require './bcm2835'
require './raw'

SPI.init

# control eyes
Thread.new do
  RAWS.each do |ix, raw|
    raise 'invalid raw length.' unless raw.size == RAW_SIZE
    addr = ix * RAW_SIZE
    SPI.write(addr, raw, SPI::CS1)
  end

  loop do
    SPI.write(1, [(COLOR << 4) + COLOR], SPI::CS0)
    sleep(3)
    SPI.write(1, [(CLOSE << 4) + CLOSE], SPI::CS0)
    sleep(0.1)
  end
end

# get from sync viewer and control led
c = HTTPClient.new
c.debug_dev = $stderr
url = "http://127.0.0.1/api/alltimeseries?epoch_time=#{Time.now.to_i - 1}"

loop do
  begin
    res = JSON.parse(c.get(url).body, symbolize_names: true)
  rescue => e
    p e
  end
  sleep(1)
  puts 'hello'
end
