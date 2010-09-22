require "sqlite3"
require "ostruct"

module ItunesConnect
  # Represents a database stored on disk.
  class Store
    # Creates a new instance. If no database file exists at the given
    # path a new one is created and the correct tables and indexes are
    # added.
    def initialize(file, verbose=false)
      @db = SQLite3::Database.new(file)
      if @db.table_info("reports").empty?
        @db.execute("CREATE TABLE reports (id INTEGER PRIMARY KEY, " +
                    "report_date DATE NOT NULL, country TEXT NOT NULL, " +
                    "install_count INTEGER, " +
                    "update_count INTEGER)")
        @db.execute("CREATE UNIQUE INDEX u_reports_idx ON reports " +
                    "(report_date, country)")
      end
      @verbose = verbose
    end

    def verbose?                # :nodoc:
      !!@verbose
    end

    # Add a record to this instance
    def add(date, country, install_count, update_count)
      ret = @db.execute("INSERT INTO reports (report_date, country, " +
                        "install_count, update_count) VALUES (?, ?, ?, ?)",
                        [format_date(date), country, install_count, update_count])
      true
    rescue SQLite3::ConstraintException => e
      if e.message =~ /columns .* are not unique/
        $stdout.puts "Skipping existing row for #{country} on #{date}" if verbose?
        false
      else
        raise e
      end
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

      if opts[:from]
        clauses << "report_date >= ?"
        params << format_date(opts[:from])
      end

      if opts[:to]
        clauses << "report_date <= ?"
        params << format_date(opts[:to])
      end

      if opts[:country]
        clauses << "country = ?"
        params << opts[:country]
      end

      sql << " WHERE " unless clauses.empty?
      sql << clauses.join(" AND ") unless params.empty?
      sql << " ORDER BY report_date DESC"

      @db.execute(sql, params).map do |row|
        OpenStruct.new({
                         :report_date => row[1] ? Date.parse(row[1]) : nil,
                         :country => row[2],
                         :install_count => row[3].to_i,
                         :update_count => row[4].to_i
                       })
      end
    end

    # Get summed counts by country, optionally constrained by dates
    # and/or country codes. Available options are:
    # <tt>:from</tt>:: The from date, defaults to the beginning
    # <tt>:to</tt>:: The end date, defaults to now
    # <tt>:country</tt>:: The country code, defaults to <tt>nil</tt>
    # which means no country code restriction
    def country_counts(opts={ })
      unless (leftovers = opts.keys - VALID_COUNT_OPTIONS).empty?
        raise "Invalid keys: #{leftovers.join(', ')}"
      end

      params = []
      clauses = []
      sql = "SELECT country, SUM(install_count), SUM(update_count) FROM reports"

      if opts[:from]
        clauses << "report_date >= ?"
        params << format_date(opts[:from])
      end

      if opts[:to]
        clauses << "report_date <= ?"
        params << format_date(opts[:to])
      end

      if opts[:country]
        clauses << "country = ?"
        params << opts[:country]
      end

      sql << " WHERE " unless clauses.empty?
      sql << clauses.join(" AND ") unless params.empty?
      sql << " GROUP BY country ORDER BY country"

      @db.execute(sql, params).map do |row|
        OpenStruct.new({
                         :country => row[0],
                         :install_count => row[1].to_i,
                         :update_count => row[2].to_i
                       })
      end
    end

    private

    def format_date(date)
      date.is_a?(Date) ? date.strftime("%Y-%m-%d") : date
    end
  end
end
