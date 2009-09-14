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
               mock(:report_date => Date.parse('2009/09/09'), :country => 'USD',
                    :install_count => 1, :update_count => 2),
               mock(:report_date => Date.parse('2009/09/09'), :country => 'GBP',
                    :install_count => 3, :update_count => 4)
              ] 
    end
    
    it 'should requests counts with no options with no qualifiers' do
      @store.should_receive(:counts).and_return(@data)
      clip = stub(:db => '/tmp/store.db', :null_object => true)
      @cmd.execute!(clip, [], @io)
      @io.string.should == "2009-09-09\tUSD\t1\t2\n" +
        "2009-09-09\tGBP\t3\t4\n"
    end

    it 'should output data with other options' do
      @store.should_receive(:counts).
        with(:to => Date.parse('2009/09/09'),
             :from => Date.parse('2009/09/01'),
             :country => 'USD').
        and_return(@data)

      clip = stub(:db => '/tmp/store.db',
                  :to => Date.parse('2009/09/09'),
                  :from => Date.parse('2009/09/01'),
                  :country => 'USD')

      @cmd.execute!(clip, [], @io)
      @io.string.should == "2009-09-09\tUSD\t1\t2\n" +
        "2009-09-09\tGBP\t3\t4\n"
    end
    
  end

  describe 'with invalid execution arguments' do
    it 'should require the :db option' do
      lambda { @cmd.execute! }.should raise_error(ArgumentError)
    end
  end
  
end
