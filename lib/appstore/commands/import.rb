module AppStore::Commands
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
end
