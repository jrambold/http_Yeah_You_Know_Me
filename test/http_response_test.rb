require 'minitest/autorun'
require 'minitest/pride'
require 'Faraday'

# test for response
class HTTP_Response_Test < Minitest::Test
  def test_server_sends_response
    skip
    response = Faraday.get 'http://127.0.0.1:9292/'

    expect = '<html><head></head><body>Hello, World! (0)'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_server_increments_response
    skip
    response = Faraday.get 'http://127.0.0.1:9292/'

    expect = '<html><head></head><body>Hello, World! (0)'

    assert_equal expect, response.body.split("<pre>")[0]

    Faraday.get 'http://127.0.0.1:9292/'
    response = Faraday.get 'http://127.0.0.1:9292/'

    expect = '<html><head></head><body>Hello, World! (2)'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_hello_page_response
    skip
    response = Faraday.get 'http://127.0.0.1:9292/hello'

    expect = '<html><head></head><body>Hello, World! (0)'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_date_time_page
    skip
    response = Faraday.get 'http://127.0.0.1:9292/datetime'

    expect = "<html><head></head><body>#{Time.now.strftime('%r on %A, %B %e, %Y')}"

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_pages_increment_correctly
    skip
    Faraday.get 'http://127.0.0.1:9292/hello'
    Faraday.get 'http://127.0.0.1:9292/hello'
    response = Faraday.get 'http://127.0.0.1:9292/hello'

    expect = '<html><head></head><body>Hello, World! (2)'

    assert_equal expect, response.body.split("<pre>")[0]

    response = Faraday.get 'http://127.0.0.1:9292'

    expect = '<html><head></head><body>Hello, World! (0)'

    assert_equal expect, response.body.split("<pre>")[0]

    response = Faraday.get 'http://127.0.0.1:9292'

    expect = '<html><head></head><body>Hello, World! (1)'

    assert_equal expect, response.body.split("<pre>")[0]

    response = Faraday.get 'http://127.0.0.1:9292/hello'

    expect = '<html><head></head><body>Hello, World! (3)'

    assert_equal expect, response.body.split("<pre>")[0]

    Faraday.get 'http://127.0.0.1:9292/datetime'
    response = Faraday.get 'http://127.0.0.1:9292/shutdown'

    expect = '<html><head></head><body>Total Requests: 8'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_word_is_a_word
    skip
    response = Faraday.get 'http://127.0.0.1:9292/word_search?w=hello'

    expect = '<html><head></head><body>hello is a known word'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_word_is_not_a_word
    skip
    response = Faraday.get 'http://127.0.0.1:9292/word_search?w=fipaloo'

    expect = '<html><head></head><body>fipaloo is not a known word'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_can_send_post_to_server
    skip
    send = Faraday.new(:url => 'http://127.0.0.1:9292')
    response = send.post '/start_game'

    expect = 'Good luck!'

    assert_equal expect, response.body.split("<pre>")[0]
  end

  def test_can_send_make_guess
    skip
    send = Faraday.new(:url => 'http://127.0.0.1:9292')
    send.post '/start_game'
    response = send.post '/game', { :guess => 1 }

    expect = 302
    assert_equal expect, response.status

    response = Faraday.get 'http://127.0.0.1:9292/game'

    expect = "<html><head></head><body>The last guess was 1 which was Too Low\nTotal Guesses: 1"
    assert_equal expect, response.body.split("<pre>")[0]

    send.post '/game', { :guess => 99 }
    response = Faraday.get 'http://127.0.0.1:9292/game'

    expect = "<html><head></head><body>The last guess was 99 which was Too High\nTotal Guesses: 2"
    assert_equal expect, response.body.split("<pre>")[0]
  end
end
