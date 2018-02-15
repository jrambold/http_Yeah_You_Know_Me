require 'minitest/autorun'
require 'minitest/pride'
require './lib/parser'

# test for parser
class HTTP_Response_Test < Minitest::Test
  def test_can_parse_start_line
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292',
                  'Connection: keep-alive',
                  'Cache-Control: max-age=0',
                  'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                  'Upgrade-Insecure-Requests: 1',
                  'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36',
                  'Accept-Encoding: gzip, deflate, sdch',
                  'Accept-Language: en-US,en;q=0.8']

    parsed = Parser.new(http_sample)

    assert_equal 'GET', parsed.verb
    assert_equal '/', parsed.path
    assert_equal 'HTTP/1.1', parsed.protocol
  end

  def test_request_date_has_info
    http_sample = ['GET / HTTP/1.1',
                  'Host: 127.0.0.1:9292',
                  'Connection: keep-alive',
                  'Cache-Control: max-age=0',
                  'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
                  'Upgrade-Insecure-Requests: 1',
                  'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.80 Safari/537.36',
                  'Accept-Encoding: gzip, deflate, sdch',
                  'Accept-Language: en-US,en;q=0.8']

    parsed = Parser.new(http_sample)

    assert_equal '127.0.0.1:9292', parsed.request_data['Host']
  end
end
