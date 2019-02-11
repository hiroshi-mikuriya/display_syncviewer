# frozen_string_literal  true
# 参考：http://akiracing.com/2018/02/04/how_to_use_mpu9250/
# レジスタマップ：https://www.invensense.com/wp-content/uploads/2015/02/RM-MPU-9250A-00-v1.6.pdf

require './bcm2835'

I2C.init
I2C.write(0x69, [0x37, 0x02]) # bypass mode(磁気センサが使用出来るようになる)
I2C.write(0x0C, [0x0A, 0x16]) # 磁気センサのAD変換開始

# センサー振れ幅。個体ごとに違う値になる。
# c = {:x=>{:min=>-243, :max=>234}, :y=>{:min=>-270, :max=>219}, :z=>{:min=>-484, :max=>-2}}
c = {:x=>{:min=>-81, :max=>513}, :y=>{:min=>-228, :max=>427}, :z=>{:min=>-271, :max=>365}}

asax, asay, asaz = I2C.read(0x0C, 0x10, 3).unpack('C*')
loop do
  if (0x01 & I2C.read(0x0C, 0x02, 1)[0].ord).zero?
    sleep(0.01)
    next
  end
  hx, hy, hz = I2C.read(0x0C, 0x03, 7).unpack('s*')
  x, y, =  { x: [hx, asax], y: [hy, asay], z: [hz, asaz] }.map do |k, (h, asa)|
    hadj = h * ((asa - 128) * 0.5 / 128 + 1)
    2.0 * (hadj - c[k][:min]) / (c[k][:max] - c[k][:min]) - 1 # -1から1に線形変換
  end
  r360 = ((Math.atan2(y, x) + Math::PI) / (2 * Math::PI) * 360).to_i # 360度に変換。北:0 東:270 南:180 西:90になるっぽい。
  p r360
end
