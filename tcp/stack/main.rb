require "./tcp"

### Run with sudo to get network permission ###

# establish tcp client
tcp_client = TCPClient.new(url: "http://www.google.com")

# establish connection
tcp_client.connect

# send http GET request
tcp_client.get_page
