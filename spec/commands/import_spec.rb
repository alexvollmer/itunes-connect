require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "tempfile"

describe ItunesConnect::Commands::Import do

  before(:each) do
    @cmd = ItunesConnect::Commands::Import.new(mock(:null_object => true),
                                          mock(:username => nil,
                                               :password => nil,
                                               :database => nil))
  end

  describe 'with valid execution arguments' do
    before(:each) do
      @store = mock(ItunesConnect::Store)
      ItunesConnect::Store.should_receive(:new).
        with("/tmp/store.db", false).
        and_return(@store)
    end

    it 'should add a record to the store for each row of data' do
      t = Date.parse('8/31/2009')
      @store.should_receive(:add).with(t, 'GB', 0, 1)
      @store.should_receive(:add).with(t, 'AR', 0, 1)
      @store.should_receive(:add).with(t, 'US', 1, 3)
      report_file = File.join(File.dirname(__FILE__), '..', 'fixtures', 'report.txt')
      @cmd.execute!(stub(:db => '/tmp/store.db',
                         :file => report_file,
                         :verbose? => false))
    end
  end

  describe 'execution argument validation' do
    it 'should reject missing all options' do
      lambda { @cmd.execute! }.should raise_error(ArgumentError)
    end

    it 'should reject missing :file option' do
      lambda do
        @cmd.execute!(stub(:db => '/tmp/store.db', :file => nil))
      end.should raise_error(ArgumentError)
    end

    it 'should reject missing :db option' do
      lambda do
        @cmd.execute!(stub(:db => nil, :file => '/tmp/report.txt', :verbose? => false))
      end.should raise_error(ArgumentError)
    end
  end

  describe 'setting up command-line parsing' do

    it 'should add appropriate options to a given Clip' do
      clip = mock('Clip')
      clip.should_receive(:opt).
        with('b', 'db',
             :desc => 'Dump report to sqlite DB at the given path')
      clip.should_receive(:req).
        with('f', 'file',
             :desc => 'The file to import, - means standard in')

      ItunesConnect::Commands::Import.new(clip)
    end
  end

end
