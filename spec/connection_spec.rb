require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require "fakeweb"

describe ItunesConnect::Connection do
  before(:each) do
    @itc = ItunesConnect::Connection.new("foo", "bar")
    FakeWeb.allow_net_connect = false
  end

  it 'should reject invalid periods' do
    lambda {
      @itc.get_report(Date.today - 1, $stdout, "Invalid")
    }.should raise_error(ArgumentError)
  end

  it 'should reject dates newer than yesterday' do
    lambda {
      @itc.get_report(Date.today, $stdout)
    }.should raise_error(ArgumentError)

    lambda {
      @itc.get_report(Date.today + 1, $stdout)
    }.should raise_error(ArgumentError)
  end

end
