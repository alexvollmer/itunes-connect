module AppStore::Commands
  
  class Download
    def initialize(c)
      c.opt('u', 'username', :desc => 'iTunes Connect username')
      c.opt('p', 'password', :desc => 'iTunes Connect password')
      c.opt('d', 'date', :desc => 'Daily report date (MM/DD/YYYY format)',
            :default => (Date.today - 1).strftime('%m/%d/%Y'))
      c.opt('o', 'out', :desc => 'Dump report to file, - is stdout')
    end

    def execute!(opts={ })
      raise ArgumentError.new("Please provide a username") unless opts[:username]
      raise ArgumentError.new("Please provide a password") unless opts[:password]
      connect = AppStore::Connect.new(opts[:username], opts[:password])
      out = opts[:out] ? File.open(opts[:out], 'w') : $stdout
      connect.get_report(opts[:date] || Date.today - 1,
                         out)

      out.flush
      out.close unless out == $stdout
    end
  end

  class Import
    def initialize(c)
      c.req('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
    end

    def execute!(opts={ })
      raise ArgumentError.new("Missing :db option") unless opts[:db]
      raise ArgumentError.new("Missing :data option") unless opts[:data]
      store = AppStore::Store.new(opts[:db])
      opts[:data].each do |x|
        store.add(x.date, x.country, x.install_count, x.update_count)
      end
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

    def execute!(opts={ })
      raise ArgumentError.new("Missing :db option") unless opts[:db]
      store = AppStore::Store.new(opts.delete(:db))

      out = opts.delete(:out) || $stdout
      store.counts(opts).each do |x|
        out.puts [x.report_date,
                  x.country,
                  x.install_count,
                  x.update_count].join("\t")
      end
      out.flush
    end
    
  end

  def self.for_name(name, clip)
    self.const_get(name.capitalize.to_sym).new(clip)
  rescue NameError => e
    nil
  end
end
