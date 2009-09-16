require "ostruct"

# This class transforms the raw input given in the constructor into a
# series of objects representing each row. You can either get the
# entire set of data by accessing the +data+ attribute, or by calling
# the +each+ method and handing it a block.
class AppStore::Report
  include Enumerable

  # The report as a Hash, where the keys are country codes and the
  # values are Hashes with the keys, <tt>:date</tt>, <tt>:upgrade</tt>,
  # <tt>:install</tt>. 
  attr_reader :data

  # Give me an +IO+-like object (one that responds to the +each+
  # method) and I'll parse that sucker for you.
  def initialize(input)
    @data = Hash.new { |h,k| h[k] = { }}
    input.each.each do |line|
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

  # Yields each parsed data row to the given block. Each item yielded
  # has the following attributes:
  #   * country
  #   * date
  #   * install_count
  #   * upgrade_count
  def each                      # :yields: record
    @data.each do |country, value|
      if block_given?
        yield OpenStruct.new(:country => country,
                             :date => value[:date],
                             :install_count => value[:install] || 0,
                             :upgrade_count => value[:upgrade] || 0)
      end
    end
  end

  # The total number of rows in the report
  def size
    @data.size
  end
end
