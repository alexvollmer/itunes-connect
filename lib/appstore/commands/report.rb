require "appstore/rc_file"
require "appstore/store"

module AppStore::Commands
  class Report                  # :nodoc:
    def initialize(c, rcfile=AppStore::RcFile.default)
      c.opt('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.opt('c', 'country',
            :desc => 'A two-letter country code to filter results with')
      c.opt('f', 'from', :desc => 'The starting date, inclusive') do |f|
        Date.parse(f)
      end
      c.opt('t', 'to', :desc => 'The ending date, inclusive') do |t|
        Date.parse(t)
      end
      c.flag('s', 'summarize', :desc => 'Summarize results by country code')
      c.flag('n', 'no-header', :desc => 'Suppress the column headers on output')
      c.opt('d', 'delimiter',
             :desc => 'The delimiter to use for output (normally TAB)',
            :default => "\t")
      c.flag('o', 'total', :desc => 'Add totals at the end of the report')
      @rcfile = rcfile
    end

    def execute!(opts, args=[], out=$stdout)
      db = opts.db || @rcfile.database || nil
      raise ArgumentError.new("Missing :db option") if db.nil?
      store = AppStore::Store.new(db)
      params = {
        :to => opts.to,
        :from => opts.from,
        :country => opts.country
      }

      total_installs, total_upgrades = 0, 0
        
      unless opts.no_header?
        out.puts([opts.summarize? ? nil : "Date",
                  "Country",
                  "Installs",
                  "Upgrades"
                 ].compact.join(opts.delimiter))
      end

      if opts.summarize?
        store.country_counts(params).each do |x|
          out.puts [x.country,
                    x.install_count,
                    x.update_count].join(opts.delimiter)
          total_installs += x.install_count
          total_upgrades += x.update_count
        end
      else
        store.counts(params).each do |x|
          out.puts [x.report_date,
                    x.country,
                    x.install_count,
                    x.update_count].join(opts.delimiter)
          total_installs += x.install_count
          total_upgrades += x.update_count
        end
      end

      if opts.total?
        out.puts ["Total",
                  opts.summarize? ? nil : "-",
                  total_installs,
                  total_upgrades
                 ].compact.join(opts.delimiter)
      end
      out.flush
    end

    def description
      "Generates reports from a local database"
    end
  end
end
