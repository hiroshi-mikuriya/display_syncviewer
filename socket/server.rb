# frozen_string_literal: true

require './sd_notify'

sleep(1)

sock = Socket.new(:UNIX, :DGRAM)
f = '/tmp/server.socket'
File.unlink(f) if File.exist? f
sock.bind Socket.sockaddr_un(f)

SdNotify.ready

loop { p sock.recvfrom(1024) }
