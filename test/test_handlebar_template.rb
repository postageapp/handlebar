require 'helper'

class TestHandlebarTemplate < Test::Unit::TestCase
  def test_empty_template
    template = Handlebar::Template.new('')
    
    assert_equal '', template.interpret
  end

  def test_simple_templates
    template = Handlebar::Template.new('example')
    
    assert_equal 'example', template.interpret

    template = Handlebar::Template.new('{{{example}}}')
    
    assert_equal '{{example}}', template.interpret
    
    template = Handlebar::Template.new('example {{example}} text')
    
    assert_equal 'example something text', template.interpret(:example => 'something')

    template = Handlebar::Template.new('example {{  example  }} text')
    
    assert_equal 'example something text', template.interpret(:example => 'something')
  end
  
  def test_boolean_templates
    template = Handlebar::Template.new('{{?boolean}}true {{/}}false')
    
    assert_equal 'false', template.interpret
    assert_equal 'true false', template.interpret(:boolean => true)
    assert_equal 'false', template.interpret(:boolean => false)
  end
    
  def test_sectioned_templates
    template = Handlebar::Template.new('<head>{{:head}}<{{tag}}>{{/}}</head>')
    
    assert_equal '<head><meta></head>', template.interpret(:head => 'meta')
    assert_equal '<head><meta><link></head>', template.interpret(:head => %w[ meta link ])
    assert_equal '<head><meta><link></head>', template.interpret(:head => [ { :tag => 'meta' }, { :tag => 'link' } ])
    assert_equal '<head></head>', template.interpret
    assert_equal '<head></head>', template.interpret(:head => nil)
    assert_equal '<head></head>', template.interpret(:head => [ ])

    template = Handlebar::Template.new('<div>{{:link}}<a href="{{href}}" alt="{{alt}}">{{/}}</div>')
    
    assert_equal '<div><a href="meta" alt=""></div>', template.interpret(:link => 'meta')
    assert_equal '<div><a href="meta" alt="link"></div>', template.interpret(:link => [ %w[ meta link ] ])
    assert_equal '<div><a href="/h" alt=""><a href="" alt="alt"><a href="/" alt="top"></div>', template.interpret(:link => [ { :href => '/h' }, { :alt => 'alt' }, { :href => '/', :alt => 'top' } ])
    assert_equal '<div></div>', template.interpret
    assert_equal '<div></div>', template.interpret(:link => nil)
    assert_equal '<div></div>', template.interpret(:link => [ ])
  end
  
  def test_template_with_context
    template = Handlebar::Template.new('{{example}}', :html)
    
    assert_equal '&lt;strong&gt;', template.interpret('<strong>')

    template = Handlebar::Template.new('{{=example}}', :html)
    
    assert_equal '<strong>', template.interpret('<strong>')
  end

  def test_recursive_templates
    template = Handlebar::Template.new('{{*example}}', :html)
    
    assert_equal 'child', template.interpret(nil, { :example => '{{*parent}}', :parent => 'child' })
  end

  def test_missing_templates
    template = Handlebar::Template.new('{{*example}}', :html)
    
    assert_equal '', template.interpret(nil, { })
  end

  def test_recursive_circular_templates
    template = Handlebar::Template.new('{{*reference}}', :html)
    
    assert_exception Handlebar::Template::RecursionError do
      template.interpret(nil, { :reference => '{{*backreference}}', :backreference => '{{*reference}}' })
    end
  end
end
