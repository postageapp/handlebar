require 'uri'
require 'cgi'

module Handlebar::Support
  def uri_escape(object)
    URI.escape(object.to_s, /[^a-z0-9\-\.]/i)
  end
  
  def html_escape(object)
    CGI.escapeHTML(object.to_s)
  end
  
  def js_escape(object)
    object.inspect
  end

  def css_escape(object)
    [ object ].flatten.join(' ')
  end
  
  def iterate(object)
    if (object.respond_to?(:each))
      object.each do |i|
        yield(i)
      end
    elsif (object)
      yield(object)
    end
  end
  
  def cast_as_vars(object, stack)
    if (object.is_a?(Hash))
      stack.each do |parent|
        if (parent.is_a?(Hash))
          object = parent.merge(object)
        end
      end
    
      object
    else
      object.respond_to?(:each) ? object : [ object ]
    end
  end
  
  extend self
end
