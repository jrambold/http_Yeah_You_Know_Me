# parses http info
class Parser
  attr_reader :game,
              :verb,
              :path,
              :params,
              :protocol,
              :request_data

  def initialize(request_lines)
    @request_lines = request_lines
    @game, @verb, @path, @params, @protocol, @request_data = [nil] * 6
    parse_start_line
    parse_request_data
  end

  def parse_start_line
    type = @request_lines[0].split
    @verb = type[0]
    @path = type[1].split('?')[0]
    @params = type[1].split('?', 2)[1]
    @protocol = type[2]
    @request_lines.delete_at(0)
  end

  def parse_request_data
    @request_data = {}
    @request_lines.each do |line|
      data = line.split(': ', 2)
      @request_data[data[0]] = data[1]
    end
  end
end
