# frozen_string_literal  true
# 参考：http://akiracing.com/2018/02/04/how_to_use_mpu9250/

require './bcm2835'

I2C.init
I2C.write(0x69, [0x37, 0x02]) # bypass mode(磁気センサが使用出来るようになる)
I2C.write(0x0C, [0x0A, 0x16]) # 磁気センサのAD変換開始

# センサー振れ幅。個体ごとに違う値になる。
c = { x: { max: 245, min: -231 },
      y: { max: 236, min: -238 },
      z: { max: -6, min: -546 } }.freeze

loop do
  if (0x01 & I2C.read(0x0C, 0x02, 1).unpack('C*').first).zero?
    sleep(0.010)
    next
  end
  res = I2C.read(0x0C, 0x03, 7)
  x0, y0, z0 = res.unpack('s*')
  x, y, = { x: x0, y: y0, z: z0 }.map do |k, v|
    1.0 * (v - c[k][:min]) / (c[k][:max] - c[k][:min]) * 2 - 1 # -1から1に線形変換
  end
  r360 = ((Math.atan2(y, x) + Math::PI) / (2 * Math::PI) * 360).to_i # 360度に変換。北:0 東:90 南:180 西:270になるっぽい。
  p r360
end
