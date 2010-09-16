require "digest/md5"
require "tempfile"
require "yaml"
require "zlib"
require "rubygems"
require "httpclient"
require "nokogiri"

module ItunesConnect

  # Abstracts the iTunes Connect website.
  # Implementation inspired by
  # http://code.google.com/p/itunes-connect-scraper/
  class Connection

    REPORT_PERIODS = ["Monthly Free", "Weekly", "Daily"]

    BASE_URL = 'https://itunesconnect.apple.com'  # login base
    REFERER_URL = 'https://reportingitc.apple.com/sales.faces'
    REPORT0_URL = 'https://reportingitc.apple.com' # :nodoc:
    REPORT1_URL = 'https://reportingitc.apple.com/vendor_default.faces'
    REPORT2_URL = 'https://reportingitc.apple.com/subdashboard.faces'
    REPORT3_URL = 'https://reportingitc.apple.com/sales.faces'
    LOGIN_URL = 'https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa'
      #'https://itts.apple.com/cgi-bin/WebObjects/Piano.woa' # :nodoc:

    # select ids:
    # theForm:datePickerSourceSelectElementSales (daily)
    # theForm:weekPickerSourceSelectElement  (weekly)
    ID_SELECT_DAILY = "theForm:datePickerSourceSelectElementSales"
    ID_SELECT_WEEKLY = "theForm:weekPickerSourceSelectElement"

    # Create a new instance with the username and password used to sign
    # in to the iTunes Connect website
    def initialize(username, password, verbose=false, debug=false)
      @username, @password = username, password
      @verbose = verbose
      @debug = true #debug
    end

    def verbose?                # :nodoc:
      !!@verbose
    end

    def debug?                  # :nodoc:
      !!@debug
    end

    # Retrieve a report from iTunes Connect. This method will return the
    # raw report file as a String. If specified, the <tt>date</tt>
    # parameter should be a <tt>Date</tt> instance, and the
    # <tt>period</tt> parameter must be one of the values identified
    # in the <tt>REPORT_PERIODS</tt> array, or this method will raise
    # and <tt>ArgumentError</tt>.
    #
    # Any dates given that equal the current date or newer will cause
    # this method to raise an <tt>ArgumentError</tt>.
    #
    def get_report(date, out, period='Daily')
      date = Date.parse(date) if String === date
      if date >= Date.today
        raise ArgumentError, "You must specify a date before today"
      end

      period = 'Monthly Free' if period == 'Monthly'
      unless REPORT_PERIODS.member?(period)
        raise ArgumentError, "'period' must be one of #{REPORT_PERIODS.join(', ')}"
      end

      # grab the home page
      doc = Nokogiri::HTML(get_content(LOGIN_URL))
      login_path = (doc/"form/@action").to_s

      # login
      # /WebObjects/iTunesConnect.woa/wo/0.0.9.3.3.2.1.1.3.1.1"
      doc = Nokogiri::HTML(post_content(login_path, {
                                         'theAccountName' => @username,
                                         'theAccountPW' => @password,
                                         '1.Continue.x' => '35',
                                         '1.Continue.y' => '16',
                                         'theAuxValue' => ''
                                       }))

      report_url = doc.to_s.match(/href="(.*?)">.*?Sales and Trends/)
      report_url = report_url ? report_url[1] : nil

      raise "internal error: could not determine report url" unless report_url

      #report_url = (doc / "//*[@name='frmVendorPage']/@action").to_s
      report_type_name = (doc / "//*[@id='selReportType']/@name").to_s
      date_type_name = (doc / "//*[@id='selDateType']/@name").to_s

      doc = Nokogiri::HTML(get_content(report_url))

      #doc = Nokogiri::HTML(get_content(REPORT3_URL))

      exit 0

=begin
      # handle first report form
      doc = Nokogiri::HTML(get_content(report_url, {
                                         report_type_name => 'Summary',
                                         date_type_name => period,
                                         'hiddenDayOrWeekSelection' => period,
                                         'hiddenSubmitTypeName' => 'ShowDropDown'
                                       }))
=end

      report_url = (doc / "//*[@name='frmVendorPage']/@action").to_s
      report_type_name = (doc / "//*[@id='selReportType']/@name").to_s
      date_type_name = (doc / "//*[@id='selDateType']/@name").to_s
      date_name = (doc / "//*[@id='dayorweekdropdown']/@name").to_s

      # now get the report
      date_str = case period
                 when 'Daily'
                   date.strftime("%m/%d/%Y")
                 when 'Weekly', 'Monthly Free'
                   date = (doc / "//*[@id='dayorweekdropdown']/option").find do |d|
                     d1, d2 = d.text.split(' To ').map { |x| Date.parse(x) }
                     date >= d1 and date <= d2
                   end[:value] rescue nil
                 end

      raise ArgumentError, "No reports are available for that date" unless date_str

      date_selection_name = period == "Daily" ? ID_SELECT_DAILY : ID_SELECT_WEEKLY

      report = get_content(report_url, {
                             report_type_name => 'Summary',
                             date_type_name => period,
                             date_name => date_str,
                             'download' => 'Download',
                             date_selection_name => date_str,
                             'hiddenSubmitTypeName' => 'Download'
                           })

      begin
        gunzip = Zlib::GzipReader.new(StringIO.new(report))
        out << gunzip.read
      rescue => e
        doc = Nokogiri::HTML(report)
        msg = (doc / "//font[@id='iddownloadmsg']").text.strip
        msg = e.message if msg == ""
        $stderr.puts "Unable to download the report, reason:"
        $stderr.puts msg
      end
    end

    private

    def client
      return @client if @client
      @client = HTTPClient.new
      if self.debug?
        cookie_path = File.join(Dir.tmpdir, "cookie_store.dat")
        client.set_cookie_store(cookie_path)
        puts "cookie store path: #{cookie_path}"
      end
      @client
    end

    def post_content(uri, query=nil, headers={ })
      method_content('post', uri, query, headers)
    end

    def get_content(uri, query=nil, headers={ })
      method_content('get', uri, query, headers)
    end

    def method_content(method, uri, query=nil, headers={ })

      if @referer
        headers = {
          'Referer' => @referer,
          'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_8; en-us) AppleWebKit/531.9 (KHTML, like Gecko) Version/4.0.3 Safari/531.9'
        }.merge(headers)
      end
      url = case uri
            when /^https?:\/\//
              uri
            else
              BASE_URL + uri
            end

      if self.debug?
        puts "#{method} #{url} with #{query.inspect}"
        puts "referer: #{@referer}"
      end

      response = client.send(method, url, query, headers)
      p response.status

      if self.debug?
        md5 = Digest::MD5.new; md5 << url; md5 << Time.now.to_s
        path = File.join(Dir.tmpdir, md5.to_s + ".html")
        out = open(path, "w") do |f|
          f << "Status: #{response.status}\n"
          f << response.header.all.map do |name, value|
            "#{name}: #{value}"
          end.join("\n")
          f << "\n\n"
          f << response.body.dump
        end
        puts "#{url} -> #{path}"
        
        @client.save_cookie_store
      end

      #response = method_content(method, response.
      if response.status == 302
        # redirect
        location = response.header['Location'].first
        puts "redirecting to #{location}" if self.debug?
        response_body = method_content(method, location)
      else
        @referer = url if response.status == 200
        response.body.dump
      end
    end

  end
end
