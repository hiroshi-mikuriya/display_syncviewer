# frozen_string_literal: true

require 'socket'

Socket.open(:UNIX, :DGRAM) do |sock|
  p addr = Socket.sockaddr_un('/tmp/server.socket')
  i = 0
  loop do
    p pkt = (i += 1).to_s
    sock.send(pkt, 0, addr)
    sleep 1
  end
end
