module AppStore::Commands
  
  class Download
    def initialize(c)
      c.opt('u', 'username', :desc => 'iTunes Connect username')
      c.opt('p', 'password', :desc => 'iTunes Connect password')
      c.opt('d', 'date', :desc => 'Daily report date (MM/DD/YYYY format)',
            :default => (Date.today - 1).strftime('%m/%d/%Y'))
      c.opt('o', 'out', :desc => 'Dump report to file, - is stdout')
    end

    def execute!(opts, args=[])
      raise ArgumentError.new("Please provide a username") if opts.username.nil?
      raise ArgumentError.new("Please provide a password") if opts.password.nil?
      connect = AppStore::Connect.new(opts.username, opts.password)
      out = if opts.out.nil?
              $stdout
            else
              opts.out == "-" ? $stdout : File.open(opts.out, "w")
            end
      connect.get_report(opts.date || Date.today - 1, out)

      out.flush
      out.close unless out == $stdout
    end

    def description
      "Retrieves reports from the iTunes Connect site"
    end
    
  end

  class Import
    def initialize(c)
      c.req('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
    end

    def execute!(opts, args=[])
      raise ArgumentError.new("Missing :db option") if opts.db.nil?
      raise ArgumentError.new("Missing :data option") if opts.data.nil?
      store = AppStore::Store.new(opts.db)
      opts.data.each do |x|
        store.add(x.date, x.country, x.install_count, x.update_count)
      end
    end

    def description
      "Imports report data into a database file"
    end
  end

  class Report
    def initialize(c)
      c.req('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.opt('f', 'from', :desc => 'The starting date, inclusive') do |f|
        Date.parse(f)
      end
      c.opt('t', 'to', :desc => 'The ending date, inclusive') do |t|
        Date.parse(t)
      end
    end

    def execute!(opts, args=[], out=$stdout)
      raise ArgumentError.new("Missing :db option") if opts.db.nil?
      store = AppStore::Store.new(opts.db)
      params = {
        :to => opts.to,
        :from => opts.from,
        :country => opts.country
      }
      store.counts(params).each do |x|
        out.puts [x.report_date,
                  x.country,
                  x.install_count,
                  x.update_count].join("\t")
      end
      out.flush
    end

    def description
      "Generates reports from a local database"
    end
  end

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

  def self.for_name(name, clip)
    self.const_get(name.capitalize.to_sym).new(clip)
  rescue NameError => e
    nil
  end

  def self.all
    [Download, Import, Report, Help]
  end

  def self.usage(msg)
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
