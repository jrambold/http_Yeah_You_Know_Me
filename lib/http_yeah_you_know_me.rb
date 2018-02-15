require 'socket'
require './lib/guessing_game'

# basic http server
class HTTP
  def initialize(port)
    @tcp_server = TCPServer.new(port)
    @count = -1
    @hello_count = -1
    @total_requests = 0
    @keep_alive = true
    @dictionary = File.read('/usr/share/dict/words').split
    @last_guess = nil
    @game = nil
  end

  def start
    while @keep_alive
      client = @tcp_server.accept
      request_lines = []
      while (line = client.gets) && !line.chomp.empty?
        request_lines << line.chomp
      end
      parse_verb(client, request_lines)
      client.close
    end
  end

  def parse_verb(client, request_lines)
    verb = request_lines[0].split(' ')[0]
    if verb == 'GET'
      response = html_wrapper(request_lines, parse_request(request_lines))
      respond(client, response)
    elsif verb == 'POST'
      parse_post(client, request_lines)
    end
  end

  def parse_post(client, request_lines)
    path = request_lines[0].split[1]
    if path == '/start_game'
      @game = GuessingGame.new
      respond(client, 'Good luck!')
    elsif path == '/game'
      guess = client.read(find_content_length(request_lines)).split('=')[1]
      @last_guess = [guess, @game.guess(guess.to_i)]
      game_redirect(client)
    end
  end

  def find_content_length(request_lines)
    index = request_lines.map { |line| line.split(': ')[0] }.index('Content-Length')
    request_lines[index].split(': ')[1].to_i
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
    when '/game'
      game_response
    when '/'
      default_response
    else
      '404 Page Not Found'
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
    if @dictionary.include?(words[0][1])
      "#{words[0][1]} is a known word"
    else
      "#{words[0][1]} is not a known word"
    end
  end

  def game_response
    "The last guess was #{@last_guess[0]} which was #{@last_guess[1]}\nTotal Guesses: #{@game.count}"
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

  def game_redirect(client)
    headers = ["http/1.1 302 Redirect",
              "Location: http://127.0.0.1/game",
              "date: #{Time.now.strftime('%a, %e %b %Y %H:%M:%S %z')}",
              "server: ruby",
              "content-type: text/html; charset=iso-8859-1\r\n\r\n"].join("\r\n")
    client.puts headers
  end
end
