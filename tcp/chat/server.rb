require "socket"

class Server
  # server -> instance that listens on port for messages
  def initialize(port:, ip:)
    @server = TCPServer.open(ip, port)
    @connections = {}
    @rooms = {}
    @clients = {}
    @connections[:server] = @server
    @connections[:rooms] = @rooms
    @connections[:clients] = @clients
  end

  # for each user connected and accepted by server, it will create a new thread object
  # and which pass the connected client as an instance to the block
  def run
    loop {
      # Thread.start -> takes arguments that it yields to block for creating thread
      #   # server#accept -> returns a new Socket object and Addrinfo object
      Thread.start(@server.accept) do |client|
        nick_name = client.gets.chomp.to_sym
        # check if client connectiont already exists
        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            puts "This username already exists"
            Thread.kill self
          end
        end
        puts "#{nick_name} #{client}"
        @connections[:clients][nick_name] = client
        client.puts "Connection established, Thank you for joining! Happy Chatting"
        # listen for client messages
        listen_for_user_messages(nick_name, client)
      end
    }
  end

  # listen for user messages and broadcast to all other users
  def listen_for_user_messages(username, client)
    loop {
      msg = client.gets.chomp
      # send a braodcast message, a message for all connected users, but not to self
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username}: #{msg}"
        end
      end
    }
  end
end

# establish server on localhost:3000
server = Server.new(ip: "localhost", port: 3000)
server.run