require "digest/md5"
require "tempfile"
require "yaml"
require "zlib"
require "rubygems"
gem 'mechanize'
require "mechanize"

# mechanize monkey patch
# handle Content-Encoding of 'agzip'
begin
  require 'mechanize/chain/body_decoding_handler'

  class Mechanize
    class Chain
      class BodyDecodingHandler
        alias :orig_handle :handle

        def handle(ctx, options = {})
          response = options[:response]
          encoding = response['Content-Encoding'] || ''
          response['Content-Encoding'] = 'gzip' if encoding.downcase == 'agzip'
          orig_handle(ctx, options)
        end
      end
    end
  end
end

module ItunesConnect

  # Abstracts the iTunes Connect website.
  # Implementation inspired by
  # http://code.google.com/p/itunes-connect-scraper/
  class Connection

    REPORT_PERIODS = ["Weekly", "Daily"]

    BASE_URL = 'https://itunesconnect.apple.com'  # login base
    REPORT_URL = 'https://reportingitc.apple.com/sales.faces'
    LOGIN_URL = 'https://itunesconnect.apple.com/WebObjects/iTunesConnect.woa'

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
      @debug = debug
      @current_period = "Daily"  # default period in reportingitc interface
    end

    def verbose?                # :nodoc:
      !!@verbose
    end

    def debug?                  # :nodoc:
      !!@debug
    end

    def logged_in?              # :nodoc:
      !!@logged_in
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
    def get_report(date, out, period = 'Daily')
      date = Date.parse(date) if String === date
      if date >= Date.today
        raise ArgumentError, "You must specify a date before today"
      end

      unless REPORT_PERIODS.member?(period)
        raise ArgumentError, "'period' must be one of #{REPORT_PERIODS.join(', ')}"
      end

      login unless self.logged_in?

      # fetch report
      # (cache report page)
      fetch_report_page unless @report_page

      # requested download date
      date_str = date.strftime("%m/%d/%Y")
      debug_msg("download date: #{date_str}")

      # determine available download options
      @select_name = period == 'Daily' ? ID_SELECT_DAILY : ID_SELECT_WEEKLY
      options = @report_page.search(".//select[@id='#{@select_name}']/option")
      options = options.collect { |i| i ? i['value'] : nil } if options
      raise "unable to determine daily report options" unless options

      debug_msg("options: #{options.inspect}")

      # constrain download to available reports
      available = options.find { |i| i <= date_str } ? true : false

      unless available
        raise ArgumentError, "No #{period} reports are available for #{date_str}"
      end

      # get ajax parameter name for Daily/Weekly (<a> id)
      report_period_link = @report_page.link_with(:text => /#{period}/)
      @report_period_id = report_period_link.node['id']
      raise "could not determine form period AJAX parameter" unless @report_period_id

      # get ajax parameter name from <select> onchange attribute
      # 'parameters':{'theForm:j_id_jsp_4933398_30':'theForm:j_id_jsp_4933398_30'}
      report_date_select = @report_page.search(".//select[@id='#{@select_name}']")
      @report_date_id = report_date_select[0]['onchange'].match(/parameters':\{'(.*?)'/)[1] rescue nil
      raise "could not determine form date AJAX parameter" unless @report_date_id

      # select report period to download (Weekly/Daily)
      if @current_period != period
        change_report(@report_page, date_str, @report_period_id => @report_period_id)
        @current_period = period
      end

      # select report date
      page = change_report(@report_page, date_str, @report_date_id => @report_date_id)

      # after selecting report type, recheck if selection is available.
      # (selection options exist even when the report isn't available, so
      #  we need to do another check here)
      dump(client, page)
      available = !page.body.match(/There is no report available for this selection/)
      unless available
        raise ArgumentError, "No #{period} reports are available for #{date_str}"
      end

      # download the report
      page = @report_page.form_with(:name => 'theForm') do |form|
        form['theForm:xyz'] = 'notnormal'
        form['theForm:downloadLabel2'] = 'theForm:downloadLabel2'
        form[@select_name] = date_str

        form.delete_field!('AJAXREQUEST')
        form.delete_field!(@report_period_id)
        form.delete_field!(@report_date_id)

        debug_form(form)
      end.submit

      dump(client, page)
      report = page.body.to_s
      debug_msg("report is #{report.length} bytes")
      out << report
      report
    end

    private

    def debug_msg(message)
      return unless self.debug?
      puts message
    end

    def change_report(report_page, date_str, params = {})
      page = report_page.form_with(:name => 'theForm') do |form|
        form.delete_field!(@report_period_id)
        form.delete_field!(@report_date_id)
        form.delete_field!('theForm:downloadLabel2')

        params.each { |k,v| form[k] = v }

        form['AJAXREQUEST'] = @ajax_id
        form['theForm:xyz'] = 'notnormal'
        form[@select_name] = date_str

        debug_form(form)
      end.submit
    end

    # fetch main report page (sales.faces)
    def fetch_report_page 
      @report_page = client.get(REPORT_URL)
      dump(client, @report_page)
            
      # get ajax parameter name for AJAXREQUEST (<a> id)
      # AJAX.Submit('theForm:j_id_jsp_4933398_2'
      @ajax_id = @report_page.body.match(/AJAX\.Submit\('([^\']+)'/)[1] rescue nil
      raise "could not determine form AJAX id" unless @ajax_id

      @report_page
    end

    # log in and navigate to the reporting interface
    def login
      debug_msg("Logging in")

      page = client.get(LOGIN_URL)

      # TODO: does expired session page occur before or after log in?
      expired = page.body.match(/Your session has expired.*?href\="(.*?)"/)
      if expired
        debug_msg("expired session detected")
        page = client.get(expired[1])
       # next  # retry login
      end

      while true do
        page = page.form_with(:name => 'appleConnectForm') do |form|
          raise "login form not found" unless form

          form['theAccountName'] = @username
          form['theAccountPW'] = @password
          form['1.Continue.x'] = '35'
          form['1.Continue.y'] = '16'
          form['theAuxValue'] = ''
        end.submit

        dump(client, page)

        break  # done logging in
      end

      # skip past new license available notifications
      new_license = page.body.match(/License Agreement Update/)
      if new_license
        debug_msg("new license detected, skipping")
        submit_parameter = page.body.match(/input.*?type\="image".*?name="(.*?)"/)[1] rescue nil
        raise "could not determine how to skip new license agreement" unless submit_parameter
        page = page.form_with(:name => 'mainForm') do |form|
          form["#{submit_parameter}.x"] = 40
          form["#{submit_parameter}.y"] = 18
        end.submit
      end

      # Click the sales and trends link
      sales_link = page.link_with(:text => /Sales and Trends/)
      raise "Sales and Trends link not found" unless sales_link
      page2 = client.click(sales_link)
      dump(client, page2)

      @report_page = nil  # clear any cached report page
      @logged_in = true
    end

    def client
      return @client if @client
      @client = Mechanize.new
      @client.user_agent_alias = 'Mac FireFox'
      @client
    end

    # dump state information to a file (debugging)
    def dump(a, page)
      return unless self.debug?

      url = a.current_page.uri.request_uri
      puts "current page: #{url}"

      md5 = Digest::MD5.new; md5 << url; md5 << Time.now.to_s
      path = File.join(Dir.tmpdir, md5.to_s + ".html")
      out = open(path, "w") do |f|
        f << "Current page: #{url}"
        f << "Headers: #{page.header}"
        f << page.body
      end

      puts "#{url} -> #{path}"
    end

    def debug_form(form)
      return unless self.debug?

      puts "\nsubmitting form:"
      form.keys.each do |key|
        puts "#{key}: #{form[key]}"
      end
    end

  end
end
