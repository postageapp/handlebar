require 'helper'

class TestHandlebar < Test::Unit::TestCase
  def test_empty_template
    template = Handlebar::Template.new('')
  end
end
