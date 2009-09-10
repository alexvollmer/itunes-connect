require "sqlite3"
require "ostruct"

module AppStore
  class Store
    def initialize(file)
      @db = SQLite3::Database.new(file)
      if @db.table_info("reports").empty?
        @db.execute("CREATE TABLE reports (id INTEGER PRIMARY KEY, report_date DATE, country TEXT, install_count INTEGER, update_count INTEGER)")
        # TODO: add indexes
      end
    end

    def add(date, country, install_count, update_count)
      # TODO: need to check for existing rows and not clobber
      @db.execute("INSERT INTO reports (report_date, country, install_count, update_count) VALUES (?, ?, ?, ?)",
                  date, country, install_count, update_count)
    end

    VALID_COUNT_OPTIONS = [:from, :to, :country]
    # Get counts optionally constrained by dates and/or country codes.
    # Available options are:
    # <tt>:from</tt>:: The from date, defaults to the beginning 
    # <tt>:to</tt>:: The end date, defaults to now
    # <tt>:country</tt>:: The country code, defaults to <tt>nil</tt>
    # which means no country code restriction
    def counts(opts={ })
      unless (leftovers = opts.keys - VALID_COUNT_OPTIONS).empty?
        raise "Invalid keys: #{leftovers.join(', ')}"
      end

      params = []
      clauses = []
      sql = "SELECT * FROM reports"
      unless opts.empty?
        if opts[:from]
          clauses << "report_date >= ?"
          params << opts[:from]
        end

        if opts[:to]
          clauses << "report_date <= ?"
          params << opts[:to]
        end

        if opts[:country]
          clauses << "country = ?"
          params << opts[:country]
        end

        sql << " WHERE "
        sql << clauses.join(" AND ")
      end

      @db.execute(sql, *params).map do |row|
        OpenStruct.new({
                         :report_date => Date.parse(row[1]),
                         :country => row[2],
                         :install_count => row[3].to_i,
                         :update_count => row[4].to_i
                       })
      end
    end
  end
end
