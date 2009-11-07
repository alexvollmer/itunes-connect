$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'itunes_connect'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|

end

def read_fixture(rel_path)
  File.readlines(File.join(File.dirname(__FILE__), rel_path)).join("\n")
end
