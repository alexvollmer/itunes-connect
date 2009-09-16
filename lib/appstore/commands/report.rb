require "appstore/store"

module AppStore::Commands
  class Report                  # :nodoc:
    def initialize(c, rcfile=File.expand_path("~/.itunesrc"))
      c.opt('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.opt('c', 'country',
            :desc => 'A two-letter country code to filter results with')
      c.opt('f', 'from', :desc => 'The starting date, inclusive') do |f|
        Date.parse(f)
      end
      c.opt('t', 'to', :desc => 'The ending date, inclusive') do |t|
        Date.parse(t)
      end
      c.flag('g', 'group', :desc => 'Group results by country code')
      @rcfile = rcfile
    end

    def execute!(opts, args=[], out=$stdout)
      db = if opts.db
             opts.db
           elsif @rcfile and File.exist?(@rcfile)
             rc = YAML.load_file(@rcfile)
             File.expand_path(rc[:database])
           else
             nil
           end
      
      raise ArgumentError.new("Missing :db option") if db.nil?
      store = AppStore::Store.new(db)
      params = {
        :to => opts.to,
        :from => opts.from,
        :country => opts.country
      }

      if opts.group?
        store.country_counts(params).each do |x|
          out.puts [x.country,
                    x.install_count,
                    x.update_count].join("\t")
        end
      else
        store.counts(params).each do |x|
          out.puts [x.report_date,
                    x.country,
                    x.install_count,
                    x.update_count].join("\t")
        end
      end
      out.flush
    end

    def description
      "Generates reports from a local database"
    end
  end
end
