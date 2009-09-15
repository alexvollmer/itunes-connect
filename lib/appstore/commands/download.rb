require "appstore/report"
require "yaml"

module AppStore::Commands
  class Download
    def initialize(c, rcfile=File.expand_path("~/.itunesrc"))
      c.opt('u', 'username', :desc => 'iTunes Connect username')
      c.opt('p', 'password', :desc => 'iTunes Connect password')
      c.opt('d', 'date', :desc => 'Daily report date (MM/DD/YYYY format)',
            :default => (Date.today - 1).strftime('%m/%d/%Y'))
      c.opt('o', 'out', :desc => 'Dump report to file, - is stdout')
      c.opt('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.opt('r', 'report',
            :desc => 'Report type. One of "Daily", "Weekly", "Monthly"',
            :default => 'Daily') do |r|
        r.capitalize
      end
      @rcfile = rcfile
    end

    def execute!(opts, args=[])
      username, password = if opts.username and opts.password
                             [opts.username, opts.password]
                           elsif File.exist?(@rcfile)
                             creds = YAML.load_file(@rcfile)
                             [creds[:username], creds[:password]]
                           else
                             [nil, nil]
                           end

      raise ArgumentError.new("Please provide a username") unless username
      raise ArgumentError.new("Please provide a password") unless password
      
      if opts.db and opts.out
        raise ArgumentError.new("You can only specify :out or :db, not both")
      end

      if opts.report =~ /^Monthly/ and opts.db
        raise ArgumentError.new("You cannot persist monthly reports to a " +
                                "database because these reports have no dates " +
                                "associated with them")
      end

      connection = AppStore::Connection.new(username, password, opts.verbose?)
      out = if opts.out.nil?
              opts.db ? StringIO.new : $stdout
            else
              opts.out == "-" ? $stdout : File.open(opts.out, "w")
            end
      connection.get_report(opts.date || Date.today - 1, out, opts.report)

      if opts.db and StringIO === out
        store = AppStore::Store.new(opts.db, opts.verbose?)
        out.rewind
        report = AppStore::Report.new(out)
        count = 0
        report.each do |entry|
          count += 1 if store.add(entry.date,
                                  entry.country,
                                  entry.install_count,
                                  entry.upgrade_count)
        end
        $stdout.puts "Inserted #{count} rows into #{opts.db}" if opts.verbose?
      end

      out.flush
      out.close unless out == $stdout
    end

    def description
      "Retrieves reports from the iTunes Connect site"
    end
  end
end
