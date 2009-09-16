require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppStore::Commands::Report do
  before(:each) do
    @cmd = AppStore::Commands::Report.new(mock(:null_object => true))
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
      clip = stub(:db => '/tmp/store.db', :group? => false, :null_object => true)
      @cmd.execute!(clip, [], @io)
      @io.string.should == "2009-09-09\tUS\t1\t2\n" +
        "2009-09-09\tGB\t3\t4\n"
    end

    it 'should output data with other options' do
      @store.should_receive(:counts).
        with(:to => Date.parse('2009/09/09'),
             :from => Date.parse('2009/09/01'),
             :country => 'US').
        and_return(@data)

      clip = stub(:db => '/tmp/store.db',
                  :group? => false,
                  :to => Date.parse('2009/09/09'),
                  :from => Date.parse('2009/09/01'),
                  :country => 'US')

      @cmd.execute!(clip, [], @io)
      @io.string.should == "2009-09-09\tUS\t1\t2\n" +
        "2009-09-09\tGB\t3\t4\n"
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
      clip = stub(:db => '/tmp/store.db', :group? => true, :null_object => true)
      @cmd.execute!(clip, [], @io)
      @io.string.should == "US\t1\t2\nGB\t3\t4\n"
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
        with('g', 'group',
             :desc => 'Group results by country code')

      AppStore::Commands::Report.new(clip)
    end
  end
  
end
