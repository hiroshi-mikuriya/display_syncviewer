# frozen_string_literal  true
# 参考：http://akiracing.com/2018/02/04/how_to_use_mpu9250/
# レジスタマップ：https://www.invensense.com/wp-content/uploads/2015/02/RM-MPU-9250A-00-v1.6.pdf

require './bcm2835'

I2C.init
I2C.write(0x69, [0x37, 0x02]) # bypass mode(磁気センサが使用出来るようになる)
I2C.write(0x0C, [0x0A, 0x16]) # 磁気センサのAD変換開始

mm = Hash.new { |h, k| h[k] = { min: 100000, max: -100000 } }

asax, asay, asaz = I2C.read(0x0C, 0x10, 3).unpack('C*')
loop do
  if (0x01 & I2C.read(0x0C, 0x02, 1)[0].ord).zero?
    sleep(0.01)
    next
  end
  hx, hy, hz = I2C.read(0x0C, 0x03, 7).unpack('s*')
  { x: [hx, asax], y: [hy, asay], z: [hz, asaz] }.each do |k, (h, asa)|
    hadj = (h * ((asa - 128) * 0.5 / 128 + 1)).to_i
    mm[k][:min] = [hadj, mm[k][:min]].min
    mm[k][:max] = [hadj, mm[k][:max]].max
  end
  p mm
end
