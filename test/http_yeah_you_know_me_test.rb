require './lib/http_yeah_you_know_me'
require 'minitest/autorun'
require 'minitest/pride'
require 'Faraday'

# test for http class
class HTTPTest < Minitest::Test
  def test_server_starts
    @server = HTTP.new(9292)
    @server.start
  end
end
