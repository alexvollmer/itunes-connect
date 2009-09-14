require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppStore::Commands::Download do
  before(:each) do
    @cmd = AppStore::Commands::Download.new(mock(:null_object => true))
    @defaults = {
      :username => 'dudeman',
      :password => 'sekret',
      :date => nil,
      :out => nil,
      :db => nil
    }
  end
  
  describe 'with valid execution arguments' do
    before(:each) do
      @connect = mock(AppStore::Connect)
      AppStore::Connect.should_receive(:new).
        with('dudeman', 'sekret').
        and_return(@connect)
    end

    it 'should call get_report correctly with no args' do
      @connect.should_receive(:get_report).with(Date.today - 1, $stdout)
      opts = stub(@defaults)
      @cmd.execute!(opts)
    end

    it 'should call get_report with date argument when given' do
      today = Date.today - 15
      @connect.should_receive(:get_report).with(today, $stdout)
      opts = stub(@defaults.merge(:date => today))
      @cmd.execute!(opts)
    end

    it 'should call get_report with File object when path is given' do
      @connect.should_receive(:get_report).with(Date.today - 1, an_instance_of(File))
      opts = stub(@defaults.merge(:out => '/tmp/foobar'))
      @cmd.execute!(opts)
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
  end
end
