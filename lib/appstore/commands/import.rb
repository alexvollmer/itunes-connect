require "appstore/report"

module AppStore::Commands
  class Import                  # :nodoc:
    def initialize(c)
      c.req('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.req('f', 'file', :desc => 'The file to import, - means standard in')
    end

    def execute!(opts, args=[])
      raise ArgumentError.new("Missing :db option") if opts.db.nil?
      raise ArgumentError.new("Missing :file option") if opts.file.nil?
      store = AppStore::Store.new(opts.db, opts.verbose?)
      input = opts.file == '-' ? $stdin : open(opts.file, 'r')
      count = 0
      AppStore::Report.new(input).each do |entry|
        count += 1 if store.add(entry.date,
                                entry.country,
                                entry.install_count,
                                entry.upgrade_count)
      end

      if opts.verbose?
        $stdout.puts "Added #{count} rows to the database"
      end
    end

    def description
      "Imports report data into a database file"
    end
  end
end
