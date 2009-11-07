require "itunes_connect/commands"

module ItunesConnect::Commands
  class Help                    # :nodoc:
    def initialize(c)
      # nothing to do here
    end

    def execute!(opts={ }, args=[], out=$stdout)
      if args.empty?
        out.puts "Available commands:"
        out.puts
        ItunesConnect::Commands.all.each do |cmd|
          out.printf("%-9s %s\n",
                     cmd.to_s.split('::').last.downcase,
                     cmd.new(Clip::Parser.new).description)
        end
      else
        cli = ItunesConnect::Commands.default_clip
        cmd = ItunesConnect::Commands.for_name(args.first, cli)
        cli.banner = "Command options for '#{cmd.class.to_s.split('::').last.downcase}':"
        raise ArgumentError.new("Unrecognized command '#{args.first}'") if cmd.nil?
        out.puts(cli.help)
      end
    end

    def description
      "Describe a particular command"
    end
  end
end
