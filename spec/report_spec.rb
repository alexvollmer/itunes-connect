require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AppStore::Report do
  describe 'when constructed with raw input' do
    before(:each) do
      @report = AppStore::Report.new(read_fixture('fixtures/report.txt'))
      @today = Date.parse('8/31/2009')
    end
    
    it 'should produce a correct "data" member field' do
      @report.data.should == {
        'US' => { :upgrade => 3, :install => 1, :date => @today },
        'GB' => { :upgrade => 1, :date => @today },
        'AR' => { :upgrade => 1, :date => @today }
      }
    end

    it 'should yield each country with "each"' do
      the_day = Date.parse('8/31/2009')
      all = @report.sort_by { |r| r.country }
      all[0].country.should == 'AR'
      all[0].install_count.should == 0
      all[0].upgrade_count.should == 1
      all[0].date.should == the_day

      all[1].country.should == 'GB'
      all[1].install_count.should == 0
      all[1].upgrade_count.should == 1
      all[1].date.should == the_day

      all[2].country.should == 'US'
      all[2].install_count.should == 1
      all[2].upgrade_count.should == 3
      all[2].date.should == the_day
    end
  end
end
