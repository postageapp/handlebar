require 'rubygems'

require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'handlebar'

class Test::Unit::TestCase
  def assert_exception(exception_class, message = nil)
    begin
      yield
    rescue exception_class
      # Expected
    else
      flunk message || "Did not raise #{exception_class}"
    end
  end
end
