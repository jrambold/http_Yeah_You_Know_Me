require_relative '../lib/http_yeah_you_know_me'
require 'minitest/autorun'
require 'minitest/pride'

# test for http class
class HTTP_Test < Minitest::Test
  def setup
    @server = HTTP.new(9292)
  end

  def test_server_gets_request
    skip
    request = @server.start

    expected = ["GET / HTTP/1.1",
                "Host: localhost:9292"]

    assert_equal expected[0], request[0]
    assert_equal expected[1], request[1]
  end

  def test_server_gets_request
    @server.start

    @server.start

    @server.start
  end



end
