require "packetfu"
require "./tcp_packet"
require "./listener"
require "uri"
require "resolv"
require "pry"

class TCPClient
  attr_accessor :state, :ip_daddr, :tcp_dst, :tcp_sport, :ack, :seq, :recv_buffer

  # TCP Finite State Machine
  CLOSED_STATE      = "CLOSED".freeze
  SYN_SENT_STATE    = "SYN-SENT".freeze
  ESTABLISHED_STATE = "ESTABLISHED".freeze
  FIN_WAIT_1_STATE  = "FIN-WAIT-1".freeze
  LAST_ACK_STATE    = "LAST-ACK".freeze

  def initialize(url:)
    # parse url
    @uri = URI.parse(url)
    @host = @uri.host

    # config for tcp packet
    @tcp_sport = Random.rand(12345..50000)
    @tcp_dst = @uri.port
    @ip_daddr = Resolv.getaddress(@host)

    # starts in closed state
    @state = CLOSED_STATE 

    # ifconfig for packet
    @config = PacketFu::Utils.whoami?

    # store how many bytes client has transmitted so far
    @seq = 0
    # store how many bytes client has received from server so far
    @ack = 0
    # keep buffer of received data
    @recv_buffer = ""

    # setup lisenter
    @listener = Listener.new(self, @config, @ip_daddr)
    # start in separate thread
    @listener_thread = Thread.new { @listener.listen }

    puts "Destination IP #{@ip_daddr}"
  end

  def connect
    send(syn_packet)
    self.state = SYN_SENT_STATE
  end

  def get_page
    @listener_thread.wakeup
    # wait until awk received
    while self.state != ESTABLISHED_STATE
      sleep(0.01)
    end
    # prepare request
    payload = "GET / HTTP/1.0\r\nHost: #{@host}\r\n\r\n"
    # send ack with payload
    send(ack_packet, payload)
  end

  def handle(pkt)
    # update ack based on tcp_seq
    @ack = pkt.tcp_seq + 1
    # update seq based on acked from server
    @seq = pkt.tcp_ack

    if pkt.tcp_flags.ack == 1
      self.state = ESTABLISHED_STATE
    end
  end

  def send(packet, payload=nil)
    if payload
      packet.payload = payload
    end

    binding.pry
    packet.to_w
  end

  def recv(buffer_size)

  end

  def syn_packet
    pkt = PacketFu::TCPPacket.new(config: @config)

    pkt.tcp_flags.syn = 1
    
    pkt.ip_daddr = @ip_daddr
    pkt.tcp_dst = @tcp_dst
    pkt.tcp_sport = @tcp_sport
    pkt.recalc

    pkt
  end

  def ack_packet
    pkt = PacketFu::TCPPacket.new(config: @config)
    pkt.tcp_flags.ack = 1
    pkt.ip_daddr = @ip_daddr
    pkt.tcp_dst = @tcp_dst
    pkt.tcp_sport = @tcp_sport
    pkt.recalc

    pkt
  end
end