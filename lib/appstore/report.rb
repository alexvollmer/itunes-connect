require "ostruct"

class AppStore::Report
  include Enumerable

  attr_reader :data
  
  def initialize(input)
    @data = Hash.new { |h,k| h[k] = { }}
    input.lines.each do |line|
      line.chomp!
      next if line =~ /^(Provider|$)/
      tokens = line.split(/\s+/)
      country = tokens[11]
      count = tokens[6].to_i
      @data[country][:date] = Date.parse(tokens[8])
      case tokens[5].to_i
      when 7
        @data[country][:upgrade] = count
      when 1
        @data[country][:install] = count
      end
    end
  end

  def each
    @data.each do |country, value|
      if block_given?
        yield OpenStruct.new(:country => country,
                             :date => value[:date],
                             :install_count => value[:install] || 0,
                             :upgrade_count => value[:upgrade] || 0)
      end
    end
  end

  def size
    @data.size
  end
end
