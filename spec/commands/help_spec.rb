require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "clip"

describe AppStore::Commands::Help do
  before(:each) do
    @cmd = AppStore::Commands::Help.new(mock(:null_object => true))
  end

  describe 'with valid execution arguments' do
    before(:each) do
      @io = StringIO.new
    end
    
    it 'should dump the "download" command usage to :out' do
      @cmd.execute!(nil, %w(download), @io)
      clip = AppStore::Commands.default_clip
      clip.banner = "Command options for 'download':"
      AppStore::Commands::Download.new(clip)
      @io.string.should == clip.help
    end

    it 'should dump the "import" command usage to :out' do
      @cmd.execute!(nil, %w(import), @io)
      clip = AppStore::Commands.default_clip
      clip.banner = "Command options for 'import':"
      AppStore::Commands::Import.new(clip)
      @io.string.should == clip.help
    end

    it 'should dump the "report" command usage to :out' do
      @cmd.execute!(nil, %w(report), @io)
      clip = AppStore::Commands.default_clip
      clip.banner = "Command options for 'report':"
      AppStore::Commands::Report.new(clip)
      @io.string.should == clip.help
    end
  end

  describe 'when no command name is given' do
    it 'should raise an ArgumentError' do
      io = StringIO.new
      @cmd.execute!(nil, [], io)
      io.string.should == <<-EOF
Available commands:

download  Retrieves reports from the iTunes Connect site
import    Imports report data into a database file
report    Generates reports from a local database
help      Describe a particular command
EOF

    end
  end

  describe 'when usage is requested for an unrecognized command' do
  
    it 'should raise an ArgumentError' do
      lambda { @cmd.execute!({ :out => @io }, %w(bazooka)) }.
        should raise_error(ArgumentError)
    end
  
  end
  
end
