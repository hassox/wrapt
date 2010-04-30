$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'wrapt'
require 'spec'
require 'spec/autorun'
require 'rack'
require 'haml'

Spec::Runner.configure do |config|

end
