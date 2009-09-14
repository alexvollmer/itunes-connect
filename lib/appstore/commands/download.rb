module AppStore::Commands
  class Download
    def initialize(c)
      c.opt('u', 'username', :desc => 'iTunes Connect username')
      c.opt('p', 'password', :desc => 'iTunes Connect password')
      c.opt('d', 'date', :desc => 'Daily report date (MM/DD/YYYY format)',
            :default => (Date.today - 1).strftime('%m/%d/%Y'))
      c.opt('o', 'out', :desc => 'Dump report to file, - is stdout')
      c.opt('b', 'db', :desc => 'Dump report to sqlite DB at the given path')
    end

    def execute!(opts, args=[])
      raise ArgumentError.new("Please provide a username") if opts.username.nil?
      raise ArgumentError.new("Please provide a password") if opts.password.nil?
      if opts.db and opts.out
        raise ArgumentError.new("You can only specify :out or :db, not both")
      end
      connect = AppStore::Connect.new(opts.username, opts.password)
      out = if opts.out.nil?
              opts.db ? StringIO.new : $stdout
            else
              opts.out == "-" ? $stdout : File.open(opts.out, "w")
            end
      connect.get_report(opts.date || Date.today - 1, out)

      if opts.db and StringIO === out
        data = Hash.new { |h,k| h[k] = { }}
        out.string.lines.to_a[1..-1].each do |line|
          tokens = line.split("\t")
          country = tokens[14]
          count = tokens[9].to_i
          case tokens[8].to_i
          when 7
            data[country][:upgrade] = count
          when 1
            data[country][:install] = count
          end
        end

        store = AppStore::Store.new(opts.db)
        data.each do |country, data|
          import_count += 1 if store.add(opts.date,
                                         country,
                                         data[:upgrade],
                                         data[:install])
        end
      end

      out.flush
      out.close unless out == $stdout
    end

    def description
      "Retrieves reports from the iTunes Connect site"
    end
  end
end
