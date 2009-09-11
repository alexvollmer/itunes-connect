require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "sqlite3"
require "tmpdir"

describe AppStore::Store do

  before(:each) do
    @tempdir = Dir.tmpdir
    @file = File.join(@tempdir, "store.db")
    @store = AppStore::Store.new(@file)
    @today = Date.parse('9/9/2009')
  end

  after(:each) do
    FileUtils.rm @file
  end

  describe "Adding rows" do
    it 'should return true for newly imported rows' do
      @store.add(@today, 'USD', 1, 2).should be_true
    end

    it 'should return false for duplicate rows' do
      @store.add(@today, 'USD', 1, 2).should be_true
      @store.add(@today, 'USD', 1, 2).should be_false
    end
  end

  describe 'counts' do
    before(:each) do
      @store.add(@today, 'USD', 10, 20)
      @store.add(@today - 1, 'USD', 11, 21)
      @store.add(@today, 'GBP', 5, 15)
      @store.add(@today - 1, 'GBP', 6, 16)
      @store.add(@today, 'FRR', 7, 17)
    end
    
    it 'should return all rows with no constraints' do
      @store.counts.size.should == 5
    end

    it 'should respect the :country constraint' do
      @store.counts(:country => 'USD').size.should == 2
      @store.counts(:country => 'GBP').size.should == 2
      @store.counts(:country => 'FRR').size.should == 1
    end

    it 'should respect the :to constraint' do
      @store.counts(:to => @today).size.should == 5
      @store.counts(:to => @today - 1).size.should == 2
    end

    it 'should respect the :from constraint' do
      @store.counts(:from => @today).size.should == 3
      @store.counts(:from => @today - 1).size.should == 5
      @store.counts(:from => @today - 2).size.should == 5
    end

    it 'should respect multiple constraints' do
      @store.counts(:from => @today, :to => @today).size.should == 3
      @store.counts(:from => @today,
                    :to => @today,
                    :country => 'USD').size.should == 1
    end
    
    it 'should return the correct fields' do
      record = @store.counts.first
      record.should be_respond_to(:report_date)
      record.should be_respond_to(:country)
      record.should be_respond_to(:install_count)
      record.should be_respond_to(:update_count)
    end
    
  end

end
