module AppStore::Commands
  class Help
    def initialize(c)
      # nothing to do here
    end

    def execute!(opts={ }, args=[], out=$stdout)
      if args.empty?
        out.puts "Available commands:"
        out.puts
        AppStore::Commands.all.each do |cmd|
          out.printf("%-9s %s\n",
                     cmd.to_s.split('::').last.downcase,
                     cmd.new(Clip::Parser.new).description)
        end
      else
        cli = Clip do |c|
          cmd = AppStore::Commands.for_name(args.first, c)
          c.banner = "Command options for '#{cmd.class.to_s.split('::').last.downcase}':"
          raise ArgumentError.new("Unrecognized command '#{args.first}'") if cmd.nil?
          out.puts(c.help)
        end
      end
    end

    def description
      "Describe a particular command"
    end
  end
end
