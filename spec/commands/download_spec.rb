require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppStore::Commands::Download do
  before(:each) do
    @cmd = AppStore::Commands::Download.new(mock(:null_object => true),
                                            mock(:username => nil,
                                                 :password => nil,
                                                 :database => nil))
    @defaults = {
      :username => 'dudeman',
      :password => 'sekret',
      :date => nil,
      :out => nil,
      :db => nil,
      :verbose? => false,
      :debug? => false,
      :report => 'Daily'
    }
  end
  
  describe 'with valid execution arguments' do
    before(:each) do
      @connection = mock(AppStore::Connection)
      AppStore::Connection.should_receive(:new).
        with('dudeman', 'sekret', false, false).
        and_return(@connection)
    end

    it 'should call get_report correctly with no args' do
      @connection.should_receive(:get_report).with(Date.today - 1, $stdout, 'Daily')
      opts = stub(@defaults)
      @cmd.execute!(opts)
    end

    it 'should call get_report with date argument when given' do
      today = Date.today - 15
      @connection.should_receive(:get_report).with(today, $stdout, 'Daily')
      opts = stub(@defaults.merge(:date => today))
      @cmd.execute!(opts)
    end

    it 'should call get_report with File object when path is given' do
      @connection.should_receive(:get_report).with(Date.today - 1,
                                                an_instance_of(File),
                                                'Daily')
      opts = stub(@defaults.merge(:out => '/tmp/foobar'))
      @cmd.execute!(opts)
    end

    it 'should use the given report type' do
      @connection.should_receive(:get_report).with(Date.today - 1, $stdout, 'Weekly')
      opts = stub(@defaults.merge({ :report => 'Weekly' }))
      @cmd.execute!(opts)
    end    

    describe 'and the :db option is specified' do
      it 'should import the results into the DB' do
        t = Date.parse('8/31/2009')
        @connection.should_receive(:get_report) do |date, io, report|
          io << read_fixture('fixtures/report.txt')
          io.flush
        end

        store = mock(AppStore::Store)
        store.should_receive(:add).with(t, 'GB', 0, 1)
        store.should_receive(:add).with(t, 'AR', 0, 1)
        store.should_receive(:add).with(t, 'US', 1, 3)
        AppStore::Store.should_receive(:new).
          with('/tmp/foobar.db', false).
          and_return(store)

        opts = stub(@defaults.merge(:db => '/tmp/foobar.db',
                                    :date => '2009/08/31'))
        @cmd.execute!(opts)
      end
    end
  end

  describe 'checking execution arguments' do
    it 'should get grumpy when no username or password is given' do
      lambda { @cmd.execute! }.should raise_error(ArgumentError)
      lambda { @cmd.execute!(stub(@defaults.merge(:password => nil))) }.
        should raise_error(ArgumentError)

      lambda { @cmd.execute!(stub(@defaults.merge(:username => nil))) }.
        should raise_error(ArgumentError)
    end
    
    it 'should reject getting both :out and :db options' do
      lambda do
        opts = stub(@defaults.merge(:db => '/tmp/foobar.db',
                                    :out => '/tmp/foobar.txt'))
        @cmd.execute!(opts)
      end.should raise_error(ArgumentError)
    end

    it 'should reject invalid report types' do
      lambda do
        opts = stub(@defaults.merge(:report => 'Glowing'))
        @cmd.execute!(opts)
      end.should raise_error(ArgumentError)
    end
    
    it 'should reject requests to store monthly reports in the database' do
      lambda do
        opts = stub(@defaults.merge(:report => 'Monthly', :db => '/tmp/foo.db'))
        @cmd.execute!(opts)
      end.should raise_error(ArgumentError)
    end
  end

  describe 'setting up command-line options' do
    it 'should add appropriate options to given Clip' do
      clip = mock('Clip')
      clip.should_receive(:opt).
        with('u', 'username',
             :desc => 'iTunes Connect username')
      clip.should_receive(:opt).
        with('p', 'password',
             :desc => 'iTunes Connect password')
      clip.should_receive(:opt).
        with('d', 'date',
             :desc => 'Daily report date (MM/DD/YYYY format)',
             :default => (Date.today - 1).strftime('%m/%d/%Y'))
      clip.should_receive(:opt).
        with('o', 'out',
             :desc => 'Dump report to file, - is stdout')
      clip.should_receive(:opt).
        with('b', 'db',
             :desc => 'Dump report to sqlite DB at the given path')
      clip.should_receive(:opt).
        with('r', 'report',
             :desc => 'Report type. One of "Daily", "Weekly", "Monthly"',
             :default => 'Daily')

      AppStore::Commands::Download.new(clip)
    end
  end
  
end
