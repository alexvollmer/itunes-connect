require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "sqlite3"
require "tmpdir"

describe ItunesConnect::Store do

  before(:each) do
    @tempdir = Dir.tmpdir
    @file = File.join(@tempdir, "store.db")
    @store = ItunesConnect::Store.new(@file)
    @today = Date.parse('9/9/2009')
  end

  after(:each) do
    FileUtils.rm @file
  end

  describe "Adding rows" do
    it 'should return true for newly imported rows' do
      @store.add(@today, 'US', 1, 2).should be_true
    end

    it 'should return false for duplicate rows' do
      @store.add(@today, 'US', 1, 2).should be_true
      @store.add(@today, 'US', 1, 2).should be_false
    end
  end

  describe 'counts' do
    before(:each) do
      @store.add(@today, 'US', 10, 20)
      @store.add(@today - 1, 'US', 11, 21)
      @store.add(@today, 'GB', 5, 15)
      @store.add(@today - 1, 'GB', 6, 16)
      @store.add(@today, 'FR', 7, 17)
    end

    it 'should return all rows with no constraints' do
      @store.counts.size.should == 5
    end

    it 'should respect the :country constraint' do
      @store.counts(:country => 'US').size.should == 2
      @store.counts(:country => 'GB').size.should == 2
      @store.counts(:country => 'FR').size.should == 1
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
                    :country => 'US').size.should == 1
    end

    it 'should return the correct fields' do
      record = @store.counts.first
      record.should be_respond_to(:report_date)
      record.should be_respond_to(:country)
      record.should be_respond_to(:install_count)
      record.should be_respond_to(:update_count)
    end
  end

  describe 'country_counts' do
    before(:each) do
      @store.add(@today, 'US', 10, 20)
      @store.add(@today - 1, 'US', 11, 21)
      @store.add(@today, 'GB', 5, 15)
      @store.add(@today - 1, 'GB', 6, 16)
      @store.add(@today, 'FR', 7, 17)
    end

    it 'should return all countries with no constraints' do
      map = map_results_by_country(@store.country_counts)
      map.size.should == 3
      map['FR'].install_count.should == 7
      map['FR'].update_count.should == 17
      map['GB'].install_count.should == 11
      map['GB'].update_count.should == 31
      map['US'].install_count.should == 21
      map['US'].update_count.should == 41
    end

    it 'should respect the :country constraint' do
      map = map_results_by_country(@store.country_counts(:country => 'US'))
      map.size.should == 1
      map['US'].install_count.should == 21
      map['US'].update_count.should == 41
    end

    it 'should respect the :to constraint' do
      r1 = map_results_by_country(@store.country_counts(:to => @today))
      r1.size.should == 3
      r1.keys.sort.should == %w(FR GB US)
      r1['GB'].install_count.should == 11
      r1['GB'].update_count.should == 31

      r2 = map_results_by_country(@store.country_counts(:to => @today - 1))
      r2.size.should == 2
      r2.keys.sort.should == %w(GB US)
      r2['GB'].install_count.should == 6
      r2['GB'].update_count.should == 16
    end

    it 'should respect the :from constraint' do
      r1 = map_results_by_country(@store.country_counts(:from => @today))
      r1.size.should == 3
      r1.keys.sort.should == %w(FR GB US)
      r1['US'].install_count.should == 10
      r1['US'].update_count.should == 20

      r2 = map_results_by_country(@store.country_counts(:from => @today - 1))
      r2.size.should == 3
      r2.keys.sort.should == %w(FR GB US)
      r2['US'].install_count.should == 21
      r2['US'].update_count.should == 41
    end

    it 'should return the correct fields' do
      record = @store.country_counts.first
      record.should be_respond_to(:country)
      record.should be_respond_to(:install_count)
      record.should be_respond_to(:update_count)
    end
  end

  def map_results_by_country(results)
    Hash[*results.map { |result| [result.country, result] }.flatten]
  end

end
