require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "tempfile"

describe ItunesConnect::Report do
  describe 'when constructed with raw input' do
    before(:each) do
      @report = ItunesConnect::Report.new(read_fixture('fixtures/report.txt'))
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
  
  describe "when constructed with a non-US report" do
    before(:each) do
      @report = ItunesConnect::Report.new(read_fixture('fixtures/report2.txt'))
      @today = Date.parse('06/01/2010')
    end
    
    it "should produce a correct 'data' member field" do
      @report.data.should == {
        'FR' => { :install => 1, :date => @today },
        'US' => { :install => 4, :date => @today },
        'GB' => { :install => 1, :date => @today },
        'SE' => { :install => 2, :date => @today }
      }
    end
    
    it "should yield each country with 'each'" do
      all = @report.sort_by { |r| r.country }
      all[0].country.should == 'FR'
      all[0].install_count.should == 1
      all[0].upgrade_count.should == 0
      all[0].date.should == @today
      
      all[1].country.should == 'GB'
      all[1].install_count.should == 1
      all[1].upgrade_count.should == 0
      all[1].date.should == @today
      
      all[2].country.should == 'SE'
      all[2].install_count.should == 2
      all[2].upgrade_count.should == 0
      all[2].date.should == @today
      
      all[3].country.should == 'US'
      all[3].install_count.should == 4
      all[3].upgrade_count.should == 0
      all[3].date.should == @today
    end
  end
  
  describe "when given invalid input" do
    it "should raise and error and write a tempfile" do
      tf = Tempfile.new('itc-test')
      tf << "This isn't going to work"
      tf.close
      tf.open
      
      error_io = StringIO.new
      lambda{ report = ItunesConnect::Report.new(tf, error_io) }.
        should raise_error
        
      errors = error_io.string.split "\n"
      file = errors[1].match(/Saved input to (.*)$/)[1]
        
      log = open(file).readlines.to_a
      log[0].should == "ERROR\n"
      log.grep "This isn't going to work\n"
    end
  end
  
  describe "when given report like found in GitHub issue 1" do
    before(:each) do
      @report = ItunesConnect::Report.new(read_fixture('fixtures/issue1.txt'))
      @today = Date.parse('06/13/2010')
    end
    
    it "should produce a correct 'data' member field" do
      @report.data.should == {
        'SE' => { :install => 2, :date => @today },
        'US' => { :install => 1, :date => @today }
      }
    end
    
    it "should yield each country with 'each'" do
      all = @report.sort_by { |r| r.country }
      all[0].country.should == 'SE'
      all[0].install_count.should == 2
      all[0].upgrade_count.should == 0
      all[0].date.should == @today
      
      all[1].country.should == 'US'
      all[1].install_count.should == 1
      all[1].upgrade_count.should == 0
      all[1].date.should == @today
    end
  end
end
