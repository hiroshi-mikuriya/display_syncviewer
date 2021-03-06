# frozen_string_literal: true

require 'httpclient'
require './bcm2835'
require './raw'
require './calc'
require './fpga'

SPI.init

# control eyes
Thread.new do
  RAWS.each do |ix, raw|
    raise 'invalid raw length.' unless raw.size == RAW_SIZE
    addr = ix * RAW_SIZE
    SPI.write(addr, raw, SPI::CS1)
  end

  loop do
    SPI.write(FPGA::OKED_SELECT, (COLOR << 4) + COLOR, SPI::CS0)
    sleep(1 + 3 * rand)
    SPI.write(FPGA::OKED_SELECT, (CLOSE << 4) + CLOSE, SPI::CS0)
    sleep(0.1)
  end
end

# get from sync viewer and control led
c = HTTPClient.new
# c.debug_dev = $stderr

{
  FPGA::LED_MODE => 0x08, # stop demo and set blink mode
  FPGA::POWER_CTRL => 0x00, # STOP Raspberry Pi Sleep Timer
  FPGA::LED_REG => [0] * 32 * 3 * 8 # clear leds
}.each { |reg, v| SPI.write(reg, v, 0) }

loop do
  begin
    url = "http://192.168.11.10/api/correlations/#{(Time.now.to_i + 10) * 1000}"
    act, amp = calc(c.get(url).body)
    puts "act: #{act}  amp: #{amp}"
    color = [[0xFF, 0x00, 0x00], [0xFF, 0x20, 0x00], [0xFF, 0xFF, 0x00],
             [0x00, 0xFF, 0x00], [0x00, 0x00, 0xFF]][amplitude_level(amp)]
    freq = [0x40, 0x20, 0x10, 0x08][activity_level(act)]
    SPI.write(FPGA::LED_FREQ, freq, 0)
    SPI.write(FPGA::LED_REG, color * 32 * 2, 0)
  rescue => e
    p e
    SPI.write(FPGA::LED_REG, [0] * 32 * 3 * 8, 0) # clear leds.
  end
  # sleep(1)
end
