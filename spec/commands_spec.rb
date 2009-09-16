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
end

