require 'helper'

class TestHandlebarTemplate < Test::Unit::TestCase
  def test_empty_template
    template = Handlebar::Template.new('')
    
    assert_equal '', template.render
  end

  def test_simple_templates
    template = Handlebar::Template.new('example')
    
    assert_equal 'example', template.render

    template = Handlebar::Template.new('{{{example}}}')
    
    assert_equal '{{example}}', template.render
    
    template = Handlebar::Template.new('example {{example}} text')
    
    assert_equal 'example something text', template.render(:example => 'something')

    template = Handlebar::Template.new('example {{  example  }} text')
    
    assert_equal 'example something text', template.render(:example => 'something')
  end
  
  def test_boolean_templates
    template = Handlebar::Template.new('{{?boolean}}true {{/}}false')
    
    assert_equal 'false', template.render
    assert_equal 'true false', template.render(:boolean => true)
    assert_equal 'false', template.render(:boolean => false)
  end
    
  def test_sectioned_templates
    template = Handlebar::Template.new('<head>{{:head}}<{{tag}}>{{/}}</head>')
    
    assert_equal '<head><meta></head>', template.render(:head => 'meta')
    assert_equal '<head><meta><link></head>', template.render(:head => %w[ meta link ])
    assert_equal '<head><meta><link></head>', template.render(:head => [ { :tag => 'meta' }, { :tag => 'link' } ])
    assert_equal '<head></head>', template.render
    assert_equal '<head></head>', template.render(:head => nil)
    assert_equal '<head></head>', template.render(:head => [ ])

    template = Handlebar::Template.new('<div>{{:link}}<a href="{{href}}" alt="{{alt}}">{{/}}</div>')
    
    assert_equal '<div><a href="meta" alt=""></div>', template.render(:link => 'meta')
    assert_equal '<div><a href="meta" alt="link"></div>', template.render(:link => [ %w[ meta link ] ])
    assert_equal '<div><a href="/h" alt=""><a href="" alt="alt"><a href="/" alt="top"></div>', template.render(:link => [ { :href => '/h' }, { :alt => 'alt' }, { :href => '/', :alt => 'top' } ])
    assert_equal '<div></div>', template.render
    assert_equal '<div></div>', template.render(:link => nil)
    assert_equal '<div></div>', template.render(:link => [ ])
  end
  
  def test_template_with_context
    template = Handlebar::Template.new('{{example}}', :escape => :html)
    
    assert_equal '&lt;strong&gt;', template.render('<strong>')

    template = Handlebar::Template.new('{{=example}}', :escape => :html)
    
    assert_equal '<strong>', template.render('<strong>')
  end

  def test_recursive_templates
    template = Handlebar::Template.new('{{*example}}', :escape => :html)
    
    assert_equal 'child', template.render(nil, { :example => '{{*parent}}', :parent => 'child' }.freeze)
  end

  def test_missing_templates
    template = Handlebar::Template.new('{{*example}}', :escape => :html)
    
    assert_equal '', template.render(nil, { })
  end

  def test_recursive_circular_templates
    template = Handlebar::Template.new('{{*reference}}', :escape => :html)
    
    assert_exception Handlebar::Template::RecursionError do
      template.render(nil, { :reference => '{{*backreference}}', :backreference => '{{*reference}}' }.freeze)
    end
  end
  
  def test_parent_templates
    parent_template = Handlebar::Template.new('{{a}}[{{*}}]{{b}}')
    child_template = Handlebar::Template.new('{{c}}{{*}}')
    final_template = Handlebar::Template.new('{{a}}')
    
    variables = { :a => 'A', :b => 'B', :c => 'C' }
    
    assert_equal 'A', final_template.render(variables)
    assert_equal 'CA', final_template.render(variables, nil, child_template)
    assert_equal 'A[CA]B', final_template.render(variables, nil, [ child_template, parent_template ].freeze)
  end
end
