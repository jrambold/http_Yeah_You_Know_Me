require 'socket'


class HTTP
  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @count = 0
  end

  def start
    @count = 0
    client = @tcp_server.accept
    puts "Ready for a request"
    request_lines = []
    while line = client.gets and !line.chomp.empty?
      request_lines << line.chomp
    end
    response(client)
    client.close
    request_lines
  end


  def response(client, request_lines)
    puts "Sending response."
    output = "<html><head></head><body>Hello, World! (#{@count})
      <pre>
      Verb: POST
      Path: /
      Protocol: HTTP/1.1
      Host: 127.0.0.1
      Port: 9292
      Origin: 127.0.0.1
      Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
      </pre></body></html>"
    headers = ["http/1.1 200 ok",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
    @count += 1
  end
end
