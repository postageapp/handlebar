require 'helper'

require 'yaml'

class TestHandlebarSupport < Test::Unit::TestCase
  def test_variable_stack
    test = { :test => [ { :a => 'a', :b => 'b' }, { :c => 'c' } ] }
    
    variables = Handlebar::Support.variable_stack(test)
    
    assert_equal test, variables
    
    assert_equal 'a', variables[:test][0][:a]
    assert_equal 'b', variables[:test][0][:b]
    assert_equal 'c', variables[:test][1][:c]

    test = { 'test' => [ { 'a' => :a, 'b' => :b }, { 'c' => :c } ] }
    
    variables = Handlebar::Support.variable_stack(test)
    
    assert_equal :a, variables[:test][0][:a]
    assert_equal :b, variables[:test][0][:b]
    assert_equal :c, variables[:test][1][:c]

    assert_equal 'test',  Handlebar::Support.variable_stack('test', false)
    assert_equal [ 'test' ],  Handlebar::Support.variable_stack('test')
    assert_equal [ 'test' ],  Handlebar::Support.variable_stack([ 'test' ], false)
    assert_equal [ 'test' ],  Handlebar::Support.variable_stack([ 'test' ])
    
    variables = Handlebar::Support.variable_stack(:head => [ { :tag => 'meta' }, { :tag => 'link' } ])
    
    assert_equal 'meta', variables[:head][0][:tag]
    assert_equal 'link', variables[:head][1][:tag]
    
    test = { 'top' => { 'layer' => 'top', 't' => 'top', 'middle' => { 'layer' => 'middle', 'm' => 'middle', 'bottom' => { 'layer' => 'bottom', 'b' => 'bottom' } } } }
    
    variables = Handlebar::Support.variable_stack(test)
    
    assert_equal 'top', variables[:top][:t]
    assert_equal 'middle', variables[:top][:middle][:m]
    assert_equal 'bottom', variables[:top][:middle][:bottom][:b]

    assert_equal 'top', variables[:top][:layer]
    assert_equal 'middle', variables[:top][:middle][:layer]
    assert_equal 'bottom', variables[:top][:middle][:bottom][:layer]
  end
end
