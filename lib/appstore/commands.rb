require "appstore/commands/download"
require "appstore/commands/import"
require "appstore/commands/report"
require "appstore/commands/help"

module AppStore::Commands
  class << self
    def for_name(name, clip)
      self.const_get(name.capitalize.to_sym).new(clip)
    rescue NameError => e
      nil
    end

    def all
      [Download, Import, Report, Help]
    end

    def usage(msg)
      $stderr.puts msg if msg
      $stderr.puts "USAGE: appstore [command] [options]"
      AppStore::Commands.all.each do |cmd_cls|
        cli = Clip do |c|
          c.banner = "'#{cmd_cls.to_s.split('::').last.downcase}' command options:"

          cmd_cls.new(c)
        end
        puts(cli.help)
        puts
      end
      exit 1
    end
  end
end
