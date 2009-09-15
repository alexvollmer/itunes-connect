require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe AppStore::Commands do

  describe 'all' do
    it 'should return all available command' do
      AppStore::Commands.all.should == [
                                        AppStore::Commands::Download,
                                        AppStore::Commands::Import,
                                        AppStore::Commands::Report,
                                        AppStore::Commands::Help
                                       ]
    end
  end

  describe 'for_name' do
    before(:each) do
      @clip = mock(:null_object => true)
    end
    
    it 'should return Download for download' do
      AppStore::Commands.for_name('download', @clip).
        should be_kind_of(AppStore::Commands::Download)
    end

    it 'should return Import for import' do
      AppStore::Commands.for_name('import', @clip).
        should be_kind_of(AppStore::Commands::Import)
    end

    it 'should return Report for report' do
      AppStore::Commands.for_name('report', @clip).
        should be_kind_of(AppStore::Commands::Report)
    end

    it 'should return Help for help' do
      AppStore::Commands.for_name('help', @clip).
        should be_kind_of(AppStore::Commands::Help)
    end
    

    it 'should return nil for other names' do
      AppStore::Commands.for_name('foobar', @clip).should be_nil
    end
  end

  describe 'Command-line options' do
    before(:each) do
      @clip = mock('Clip')
    end
    
    describe 'Download' do
      it 'should add appropriate options to given Clip' do
        @clip.should_receive(:opt).
          with('u', 'username',
               :desc => 'iTunes Connect username')
        @clip.should_receive(:opt).
          with('p', 'password',
               :desc => 'iTunes Connect password')
        @clip.should_receive(:opt).
          with('d', 'date',
               :desc => 'Daily report date (MM/DD/YYYY format)',
               :default => (Date.today - 1).strftime('%m/%d/%Y'))
        @clip.should_receive(:opt).
          with('o', 'out',
               :desc => 'Dump report to file, - is stdout')
        @clip.should_receive(:opt).
          with('b', 'db',
               :desc => 'Dump report to sqlite DB at the given path')

        AppStore::Commands::Download.new(@clip)
      end
    end

    describe 'Import' do
      it 'should add appropriate options to a given Clip' do
        @clip.should_receive(:req).
          with('b', 'db',
               :desc => 'Dump report to sqlite DB at the given path')
        @clip.should_receive(:req).
          with('f', 'file',
               :desc => 'The file to import, - means standard in')

        AppStore::Commands::Import.new(@clip)
      end
    end
    
    describe 'Report' do
      it 'should add appropriate options to a given Clip' do
        @clip.should_receive(:req).
          with('b', 'db',
               :desc => 'Dump report to sqlite DB at the given path')
        @clip.should_receive(:opt).
          with('c', 'country',
               :desc => 'A two-letter country code to filter results with')
        @clip.should_receive(:opt).
          with('f', 'from',
               :desc => 'The starting date, inclusive')
        @clip.should_receive(:opt).
          with('t', 'to',
               :desc => 'The ending date, inclusive')
        @clip.should_receive(:flag).
          with('g', 'group',
               :desc => 'Group results by country code')

        AppStore::Commands::Report.new(@clip)
      end
    end
  end
end

