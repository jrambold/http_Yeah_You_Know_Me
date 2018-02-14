require 'socket'

# basic http server
class HTTP
  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @count = -1
    @hello_count = -1
    @total_requests = 0
    @keep_alive = true
    @dictionary = File.read('/usr/share/dict/words').split('\n')
  end

  def start
    while @keep_alive
      client = @tcp_server.accept
      request_lines = []
      while (line = client.gets) && !line.chomp.empty?
        request_lines << line.chomp
      end
      response = html_wrapper(request_lines, parse_request(request_lines))
      respond(client, response)
      client.close
    end
  end

  def parse_request(request_lines)
    @total_requests += 1
    request = request_lines[0].split(' ')[1]
    request = request.split('?')
    case request[0]
    when '/hello'
      hello_response
    when '/datetime'
      date_time_response
    when '/word_search'
      word_search(request[1])
    when '/shutdown'
      @keep_alive = false
      shutdown_response
    else
      default_response
    end
  end

  def html_wrapper(request_lines, body)
    "<html><head></head><body>#{body}#{footer(request_lines)}</body></html>"
  end

  def footer(request_lines)
    "<pre>#{request_lines.join("\n")}</pre>"
  end

  def default_response
    @count += 1
    "Hello, World! (#{@count})"
  end

  def hello_response
    @hello_count += 1
    "Hello, World! (#{@hello_count})"
  end

  def date_time_response
    Time.now.strftime('%r on %A, %B %e, %Y')
  end

  def word_search(params)
    params = params.split('&')
    words = params.map { |param| param.split('=') }
    if @dictionary.include?(words[1])
      "#{words[1]}is a known word"
    else
      "#{words[1]} is not a known word"
    end
  end

  def respond(client, output)
    headers = ["http/1.1 200 ok",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
  end
end
