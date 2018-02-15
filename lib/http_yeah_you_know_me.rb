require 'socket'
require './lib/guessing_game'

# basic http server
class HTTP
  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @count, @hello_count = [-1] * 2
    @total_requests = 0
    @keep_alive = true
    @dictionary = File.read('/usr/share/dict/words').split
    @game, @verb, @path, @params, @protocol, @request_data = [nil] * 6
  end

  def start
    while @keep_alive
      client = @tcp_server.accept
      request_lines = []
      while (line = client.gets) && !line.chomp.empty?
        request_lines << line.chomp
      end
      parse_data(request_lines)
      parse_verb(client)
      client.close
    end
  end

  def parse_data(request_lines)
    type = request_lines[0].split
    @verb = type[0]
    @path = type[1].split('?')[0]
    @params = type[1].split('?', 2)[1]
    @protocol = type[2]
    request_lines.delete_at(0)
    parse_request_data(request_lines)
  end

  def parse_request_data(request_lines)
    @request_data = {}
    request_lines.each do |line|
      data = line.split(': ', 2)
      @request_data[data[0]] = data[1]
    end
  end

  def parse_verb(client)
    if @verb == 'GET'
      response = path_response
      if response == '404 Not Found'
        respond_not_found(client)
      else
        respond(client, html_wrapper(response))
      end
    elsif @verb == 'POST'
      parse_post(client)
    end
  end

  def path_response
    @total_requests += 1
    case @path
    when '/'
      root_response
    when '/hello'
      hello_response
    when '/datetime'
      date_time_response
    when '/word_search'
      word_search
    when '/game'
      game_response
    when '/shutdown'
      @keep_alive = false
      shutdown_response
    else
      '404 Not Found'
    end
  end

  def parse_post(client)
    if @path == '/start_game' && !@game
      @game = GuessingGame.new
      game_start_redirect(client)
    elsif @path == '/start_game'
      respond_forbidden_game(client)
    elsif @path == '/game'
      guess = client.read(find_content_length).split('&')[0].split('=')[1].to_i
      @game.guess(guess)
      game_redirect(client)
    end
  end

  def find_content_length
    @request_data['Content-Length'].to_i
  end

  def root_response
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

  def word_search
    words = @params.split('&').map { |word| word.split('=') }
    if @dictionary.include?(words[0][1])
      "#{words[0][1]} is a known word"
    else
      "#{words[0][1]} is not a known word"
    end
  end

  def game_response
    "The last guess was #{@game.last_guess} which was #{@game.over_under}\nTotal Guesses: #{@game.count}"
  end

  def html_wrapper(body)
    "<html><head></head><body>#{body}#{footer}</body></html>"
  end

  def footer
    "<pre>
    Verb: #{@verb}
    Path: #{@path}
    Protocol: #{@protocol}
    Host: #{@request_data['Host'].split(':')[0]}
    Port: #{@request_data['Host'].split(':', 2)[1]}
    Origin: '127.0.0.1'
    Accept: #{@request_data['Accept']}
    </pre>"
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

  def game_start_redirect(client)
    output = 'Good luck!'
    headers = ["http/1.1 301 Redirect",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
  end

  def game_redirect(client)
    headers = ["http/1.1 302 Redirect",
              "Location: http://127.0.0.1/game",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1\r\n\r\n"].join("\r\n")
    client.puts headers
  end

  def respond_forbidden_game(client)
    output = html_wrapper('403 Forbidden - Game Already Started')
    headers = ["http/1.1 403 Forbidden",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
  end

  def respond_not_found(client)
    output = html_wrapper('404 Not Found')
    headers = ["http/1.1 404 Not Found",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
  end
end
