require "yaml"

class ItunesConnect::RcFile          # :nodoc:

  DEFAULT_RCFILE_PATH = File.expand_path("~/.itunesrc")

  def self.default
    self.new(DEFAULT_RCFILE_PATH)
  end

  def initialize(path=DEFAULT_RCFILE_PATH)
    if File.exist?(path)
      @rc = YAML.load_file(path)
    else
      @rc = { }
    end
  end

  def username
    @rc[:username]
  end

  def password
    @rc[:password]
  end

  def database
    @rc[:database]
  end
end
