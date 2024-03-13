require "packetfu"
require "./tcp"

class Listener
  def initialize(conn, config, ip_daddr)
    @conn = conn
    # filter only tcp packets send from my ip or received from ip_daddr
    @cap = PacketFu::Capture.new(
      iface: config[:iface],
      start: true,
      filter: "tcp and dst #{config[:ip_saddr]} and src #{ip_daddr}"
    )
  end

  # parse pkt and decide what to do next
  def listen
    @cap.stream.each do |pkt|
      state = @conn.handle(PacketFu::Packet.parse(pkt))
      return if state == TCPClient::CLOSED_STATE
    end
  end
end