# frozen_string_literal  true
# 参考：http://akiracing.com/2018/02/04/how_to_use_mpu9250/
# レジスタマップ：https://www.invensense.com/wp-content/uploads/2015/02/RM-MPU-9250A-00-v1.6.pdf

require './bcm2835'

I2C.init
I2C.write(0x69, [0x37, 0x02]) # bypass mode(磁気センサが使用出来るようになる)
I2C.write(0x0C, [0x0A, 0x0F]) # Fuse ROM access mode
asax, asay, asaz = I2C.read(0x0C, 0x10, 3).unpack('C*')
I2C.write(0x0C, [0x0A, 0x00]) # Power-down mode
I2C.write(0x0C, [0x0A, 0x16]) # 16bits, Continuous measurement mode 2

# センサー振れ幅。個体ごとに違う値になる。
c = {:x=>{:min=>-212, :max=>279}, :y=>{:min=>-265, :max=>285}, :z=>{:min=>-620, :max=>179}}

loop do
  if (0x01 & I2C.read(0x0C, 0x02, 1)[0].ord).zero?
    sleep(0.01)
    next
  end
  res = I2C.read(0x0C, 0x03, 7)
  next unless (res[6].ord & 0x08).zero? # overflow

  hx, hy, hz = res.unpack('s*')
  x, y, =  { x: [hx, asax], y: [hy, asay], z: [hz, asaz] }.map do |k, (h, asa)|
    hadj = h * ((asa - 128) * 0.5 / 128 + 1)
    2.0 * (hadj - c[k][:min]) / (c[k][:max] - c[k][:min]) - 1 # -1から1に線形変換
  end
  r360 = ((Math.atan2(y, x) + Math::PI) / (2 * Math::PI) * 360).to_i # 360度に変換。北:0 東:270 南:180 西:90になるっぽい。
  p r360
end
