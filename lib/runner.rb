require './lib/http_yeah_you_know_me'

@server = HTTP.new(9292)
@server.start
