require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AppStore::Commands::Import do

  before(:each) do
    @cmd = AppStore::Commands::Import.new(mock(:null_object => true))
  end

  describe 'with valid execution arguments' do
    before(:each) do
      @store = mock(AppStore::Store)
      AppStore::Store.should_receive(:new).
        with("/tmp/store.db").
        and_return(@store)
    end
    
    it 'should add a record to the store for each row of data' do
      t = Date.today
      data = [
              mock(:date => t, :country => 'USD',
                   :install_count => 1, :update_count => 2),
              mock(:date => t, :country => 'GBP',
                   :install_count => 3, :update_count => 4)
             ]
      @store.should_receive(:add).with(t, 'USD', 1, 2)
      @store.should_receive(:add).with(t, 'GBP', 3, 4)
      @cmd.execute!(:db => '/tmp/store.db', :data => data)
    end
  end

  describe 'execution argument validation' do
    it 'should reject missing options' do
      lambda { @cmd.execute! }.should raise_error(ArgumentError)
      lambda { @cmd.execute!(:db => '/tmp/store.db') }.should raise_error(ArgumentError)
      lambda { @cmd.execute!(:data => []) }.should raise_error(ArgumentError)
    end
  end

end
