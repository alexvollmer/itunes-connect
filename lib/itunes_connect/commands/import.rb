require "itunes_connect/rc_file"
require "itunes_connect/report"

module ItunesConnect::Commands
  class Import                  # :nodoc:
    def initialize(c, rcfile=ItunesConnect::RcFile.default)
      c.opt('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.req('f', 'file', :desc => 'The file to import, - means standard in')
      @rcfile = rcfile
    end

    def execute!(opts, args=[])
      db = opts.db || @rcfile.database || nil
      raise ArgumentError.new("Missing :db option") unless db
      raise ArgumentError.new("Missing :file option") if opts.file.nil?
      store = ItunesConnect::Store.new(db, opts.verbose?)
      input = opts.file == '-' ? $stdin : open(opts.file, 'r')
      count = 0
      ItunesConnect::Report.new(input).each do |entry|
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
