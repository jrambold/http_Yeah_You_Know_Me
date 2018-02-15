require 'socket'
require './lib/guessing_game'
require './lib/parser'

# basic http server
class HTTP
  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @count, @hello_count = [-1] * 2
    @total_requests = 0
    @keep_alive = true
    @parsed = nil
    @game = nil
    @dictionary = File.read('/usr/share/dict/words').split
  end

  def start
    while @keep_alive
      client = @tcp_server.accept
      request_lines = []
      while (line = client.gets) && !line.chomp.empty?
        request_lines << line.chomp
      end
      @parsed = Parser.new(request_lines)
      verb_decision(client)
      client.close
    end
  end

  def verb_decision(client)
    if @parsed.verb == 'GET'
      response = path_response
      if @parsed.path == '/force_error'
        respond_system_error(client, error_response)
      elsif response == '404 Not Found'
        respond_not_found(client)
      else
        respond(client, html_wrapper(response))
      end
    elsif @parsed.verb == 'POST'
      parse_post(client)
    end
  end

  def path_response
    @total_requests += 1
    case @parsed.path
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
    if @parsed.path == '/start_game' && !@game
      @game = GuessingGame.new
      game_start_redirect(client)
    elsif @parsed.path == '/start_game'
      respond_forbidden_game(client)
    elsif @parsed.path == '/game'
      guess = client.read(find_content_length).split('&')[0].split('=')[1].to_i
      @game.guess(guess)
      game_redirect(client)
    end
  end

  def find_content_length
    @parsed.request_data['Content-Length'].to_i
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
    words = @parsed.params.split('&').map { |word| word.split('=') }
    if @dictionary.include?(words[0][1])
      "#{words[0][1]} is a known word"
    else
      "#{words[0][1]} is not a known word"
    end
  end

  def game_response
    "The last guess was #{@game.last_guess} which was #{@game.over_under}\nTotal Guesses: #{@game.count}"
  end

  def shutdown_response
    "Total Requests: #{@total_requests}"
  end

  def error_response
    ArgumentError.new("Everything Broke")
  end

  def html_wrapper(body)
    "<html><head></head><body>#{body}#{footer}</body></html>"
  end

  def footer
    "<pre>
    Verb: #{@parsed.verb}
    Path: #{@parsed.path}
    Protocol: #{@parsed.protocol}
    Host: #{@parsed.request_data['Host'].split(':')[0]}
    Port: #{@parsed.request_data['Host'].split(':', 2)[1]}
    Origin: '127.0.0.1'
    Accept: #{@parsed.request_data['Accept']}
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

  def respond_system_error(client, error)
    output = html_wrapper("500 Internal Server Error\n#{error}")
    headers = ["http/1.1 500 Not Found",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1",
              "content-length: #{output.length}\r\n\r\n"].join("\r\n")
    client.puts headers
    client.puts output
    raise error
  end
end
