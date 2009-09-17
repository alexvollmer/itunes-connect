require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppStore::Commands::Report do
  before(:each) do
    @cmd = AppStore::Commands::Report.new(mock(:null_object => true))
    @defaults = {
      :db => '/tmp/store.db',
      :summarize? => false,
      :to => nil,
      :from => nil,
      :country => nil,
      :no_header? => false,
      :delimiter => "\t",
      :total? => false
    }
  end

  describe 'with valid execution arguments' do
    before(:each) do
      @store = mock(AppStore::Store)
      AppStore::Store.should_receive(:new).
        with("/tmp/store.db").
        and_return(@store)
      @io = StringIO.new
      @data = [
               mock(:report_date => Date.parse('2009/09/09'), :country => 'US',
                    :install_count => 1, :update_count => 2),
               mock(:report_date => Date.parse('2009/09/09'), :country => 'GB',
                    :install_count => 3, :update_count => 4)
              ] 
    end
    
    it 'should request counts with no options with no qualifiers' do
      @store.should_receive(:counts).and_return(@data)
      clip = stub(@defaults.merge(:db => '/tmp/store.db'))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Date\tCountry\tInstalls\tUpgrades
2009-09-09\tUS\t1\t2
2009-09-09\tGB\t3\t4
EOF
    end

    it 'should output data with other options' do
      @store.should_receive(:counts).
        with(:to => Date.parse('2009/09/09'),
             :from => Date.parse('2009/09/01'),
             :country => 'US').
        and_return(@data)

      clip = stub(@defaults.merge(:db => '/tmp/store.db',
                                  :to => Date.parse('2009/09/09'),
                                  :from => Date.parse('2009/09/01'),
                                  :country => 'US'))

      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Date\tCountry\tInstalls\tUpgrades
2009-09-09\tUS\t1\t2
2009-09-09\tGB\t3\t4
EOF
    end

    it 'should suppress the header when requested' do
      @store.should_receive(:counts). and_return(@data)
      clip = stub(@defaults.merge(:no_header? => true))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
2009-09-09\tUS\t1\t2
2009-09-09\tGB\t3\t4
EOF
    end

    it 'should separate fields with specified delimiter' do
      @store.should_receive(:counts). and_return(@data)
      clip = stub(@defaults.merge(:delimiter => "|"))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Date|Country|Installs|Upgrades
2009-09-09|US|1|2
2009-09-09|GB|3|4
EOF
    end

    it 'should output totals when the "totals" flag is specified' do
      @store.should_receive(:counts). and_return(@data)
      clip = stub(@defaults.merge(:total? => true))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Date\tCountry\tInstalls\tUpgrades
2009-09-09\tUS\t1\t2
2009-09-09\tGB\t3\t4
Total\t-\t4\t6
EOF
    end
  end

  describe 'with :group option specified' do
    before(:each) do
      @store = mock(AppStore::Store)
      AppStore::Store.should_receive(:new).
        with('/tmp/store.db').
        and_return(@store)

      @io = StringIO.new
      @data = [
               mock(:country => 'US', :install_count => 1, :update_count => 2),
               mock(:country => 'GB', :install_count => 3, :update_count => 4)
              ]
    end
    
    it 'should request grouped country data' do
      @store.should_receive(:country_counts).and_return(@data)
      clip = stub(@defaults.merge(:summarize? => true))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Country\tInstalls\tUpgrades
US\t1\t2
GB\t3\t4
EOF
    end

    it 'should suppress the header when requested' do
      @store.should_receive(:country_counts).and_return(@data)
      clip = stub(@defaults.merge(:summarize? => true, :no_header? => true))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
US\t1\t2
GB\t3\t4
EOF
    end

    it 'should separate fields with the specified delimiter' do
      @store.should_receive(:country_counts).and_return(@data)
      clip = stub(@defaults.merge(:summarize? => true, :delimiter => '|'))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Country|Installs|Upgrades
US|1|2
GB|3|4
EOF
    end

    it 'should output totals when the "totals" flag is specified' do
      @store.should_receive(:country_counts).and_return(@data)
      clip = stub(@defaults.merge(:summarize? => true, :total? => true))
      @cmd.execute!(clip, [], @io)
      @io.string.should == <<EOF
Country\tInstalls\tUpgrades
US\t1\t2
GB\t3\t4
Total\t4\t6
EOF
    end
  end

  describe 'with invalid execution arguments' do
    it 'should require the :db option' do
      lambda { @cmd.execute! }.should raise_error(ArgumentError)
    end
  end

  describe 'command-line option parsing' do
    it 'should add appropriate options to a given Clip' do
      clip = mock("Clip")
      clip.should_receive(:opt).
        with('b', 'db',
             :desc => 'Dump report to sqlite DB at the given path')
      clip.should_receive(:opt).
        with('c', 'country',
             :desc => 'A two-letter country code to filter results with')
      clip.should_receive(:opt).
        with('f', 'from',
             :desc => 'The starting date, inclusive')
      clip.should_receive(:opt).
        with('t', 'to',
             :desc => 'The ending date, inclusive')
      clip.should_receive(:flag).
        with('s', 'summarize',
             :desc => 'Summarize results by country code')
      clip.should_receive(:flag).
        with('n', 'no-header',
             :desc => 'Suppress the column headers on output')
      clip.should_receive(:opt).
        with('d', 'delimiter',
             :desc => 'The delimiter to use for output (normally TAB)',
             :default => "\t")
      clip.should_receive(:flag).
        with('o', 'total', :desc => 'Add totals at the end of the report')

      AppStore::Commands::Report.new(clip)
    end
  end
  
end
