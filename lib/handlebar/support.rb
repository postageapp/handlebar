require 'uri'
require 'cgi'

module Handlebar::Support
  def uri_escape(object)
    URI.escape(object.to_s)
  end
  
  def html_escape(object)
    CGI.escapeHTML(object.to_s)
  end
  
  def js_escape(object)
    object.inspect
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
  
  def cast_as_vars(object)
    object.respond_to?(:each) ? object : [ object ]
  end
  
  extend self
end
