require_relative 'test_helper'
require 'minitest/autorun'
require 'minitest/pride'
require './lib/http_yeah_you_know_me'
require 'socket'
require './lib/parser'
require 'mocha/mini_test'
require './lib/guessing_game'

# test for guessing_game
class HTTPTest < Minitest::Test
  def setup
    @server = HTTP.new(9292)
  end

  def test_instantiation
    assert_instance_of HTTP, @server
    @server.tcp_server.close
  end

  def test_has_attributes
    assert_instance_of TCPServer, @server.tcp_server
    assert_equal -1, @server.count
    assert_equal -1, @server.hello_count
    assert_equal 0, @server.total_requests
    assert @server.keep_alive
    assert_nil @server.parsed
    assert_nil @server.game
    assert_equal 235886, @server.dictionary.length
    @server.tcp_server.close
  end

  def test_parse
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_instance_of Parser, @server.parsed

    @server.tcp_server.close
  end

  def test_verb_decision
    client = mock
    client.stubs(:puts)

    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'respond', @server.verb_decision(client)

    http_sample = ['GET /asdf HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'not_found', @server.verb_decision(client)

    http_sample = ['POST /start_game HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'game_start_redirect', @server.verb_decision(client)

    http_sample = ['GET /force_error HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_instance_of ArgumentError, @server.verb_decision(client)

    http_sample = ['GET /shutdown HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'respond', @server.verb_decision(client)

    @server.tcp_server.close
  end

  def test_path_response
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'Hello, World! (0)', @server.path_response

    http_sample = ['GET /hello HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'Hello, World! (0)', @server.path_response

    http_sample = ['GET /datetime HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal Time.now.strftime('%r on %A, %B %e, %Y'), @server.path_response

    http_sample = ['GET /word_search?word=hello HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'hello is a known word', @server.path_response

    http_sample = ['GET /shutdown HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    expected = "Total Requests: #{@server.total_requests+1}"
    assert_equal expected, @server.path_response

    http_sample = ['GET /asdf HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal '404 Not Found', @server.path_response

    @server.tcp_server.close
  end

  def test_parse_post
    client = mock
    client.stubs(:puts)
    client.stubs(:read).returns('guess=101')
    http_sample = ['POST /start_game HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'game_start_redirect', @server.parse_post(client)

    assert_instance_of GuessingGame, @server.game

    http_sample = ['POST /start_game HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'forbidden_game', @server.parse_post(client)

    http_sample = ['POST /game HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal 'game_redirect', @server.parse_post(client)


    @server.tcp_server.close
  end

  def test_find_content_length
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292',
                  'Content-Length: 8']
    @server.parse(http_sample)

    assert_equal 8, @server.find_content_length
    @server.tcp_server.close
  end

  def test_hello_response
    assert_equal "Hello, World! (0)", @server.root_response
    assert_equal "Hello, World! (1)", @server.root_response
    @server.tcp_server.close
  end

  def test_hello_response
    assert_equal "Hello, World! (0)", @server.hello_response
    assert_equal "Hello, World! (1)", @server.hello_response
    @server.tcp_server.close
  end

  def test_date_time_response
    assert_equal Time.now.strftime('%r on %A, %B %e, %Y'), @server.date_time_response
    @server.tcp_server.close
  end

  def test_word_search
    http_sample = ['GET /word_search?word=hello HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal "hello is a known word", @server.word_search

    http_sample = ['GET /word_search?word=helloo HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    assert_equal "helloo is not a known word", @server.word_search

    @server.tcp_server.close
  end

  def test_game_response
    game = GuessingGame.new
    game.guess(-1)
    @server.game = game
    expected = "The last guess was -1 which was Too Low\nTotal Guesses: 1"

    assert_equal expected, @server.game_response
    @server.tcp_server.close
  end

  def test_shutdown_response
    response = @server.shutdown_response

    refute @server.keep_alive
    assert_equal "Total Requests: 0", response
    @server.tcp_server.close
  end

  def test_error_response
    assert_equal ArgumentError.new('Everything Broke'), @server.error_response
    @server.tcp_server.close
  end

  def test_html_wrapper
    http_sample = ['GET /asdf HTTP/1.1',
                  'Host: 127.0.0.1:9292']
    @server.parse(http_sample)

    expected = @server.html_wrapper('asdf').split('<pre>')[0]
    assert_equal '<html><head></head><body>asdf', expected

    @server.tcp_server.close
  end

  def test_footer
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292',
                  'Accept: hi']
    @server.parse(http_sample)

    expected = "<pre>
Verb: GET
Path: /
Protocol: HTTP/1.1
Host: 127.0.0.1
Port: 9292
Origin: '127.0.0.1'
Accept: hi
</pre>"

    assert_equal expected, @server.footer

    @server.tcp_server.close
  end

  def test_respond
    client = mock
    client.stubs(:puts)

    assert 'respond', @server.respond(client, 'hello')
    @server.tcp_server.close
  end

  def test_start_redirect
    client = mock
    client.stubs(:puts)

    assert 'game_start_redirect', @server.game_start_redirect(client)
    @server.tcp_server.close
  end

  def test_game_redirect
    client = mock
    client.stubs(:puts)

    assert 'game_redirect', @server.game_redirect(client)
    @server.tcp_server.close
  end

  def test_forbidden_game
    http_sample = ['GET / HTTP/1.1',
                    'Host: 127.0.0.1:9292']
    @server.parse(http_sample)
    client = mock
    client.stubs(:puts)

    assert 'forbidden_game', @server.respond_forbidden_game(client)
    @server.tcp_server.close
  end

  def test_respond_not_found
    http_sample = ['GET / HTTP/1.1',
                    'Host: 127.0.0.1:9292']
    @server.parse(http_sample)
    client = mock
    client.stubs(:puts)

    assert 'not_found', @server.respond_not_found(client)
    @server.tcp_server.close
  end

  def test_respond_system_error
    http_sample = ['GET / HTTP/1.1',
                    'Host: 127.0.0.1:9292']
    @server.parse(http_sample)
    client = mock
    client.stubs(:puts)

    assert 'bad', @server.respond_system_error(client, 'bad')
    @server.tcp_server.close
  end

end
