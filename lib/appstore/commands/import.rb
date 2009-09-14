require "appstore/report"

module AppStore::Commands
  class Import
    def initialize(c)
      c.req('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
      c.req('f', 'file', :desc => 'The file to import, - means standard in')
    end

    def execute!(opts, args=[])
      raise ArgumentError.new("Missing :db option") if opts.db.nil?
      raise ArgumentError.new("Missing :file option") if opts.file.nil?
      store = AppStore::Store.new(opts.db)
      input = opts.file == '-' ? $stdin : open(opts.file, 'r')
      AppStore::Report.new(input).each do |entry|
        store.add(entry.date,
                  entry.country,
                  entry.install_count,
                  entry.upgrade_count)
      end
    end

    def description
      "Imports report data into a database file"
    end
  end
end
