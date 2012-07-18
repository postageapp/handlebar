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
  
  def variable_stack(variables, force_as_array = true)
    case (variables)
    when Hash
      remapped = Hash[
        variables.collect do |k, v|
          [ k ? k.to_sym : k, variable_stack(v, false) ]
        end
      ]
      
      if (default = variables.default)
        remapped.default = default
      end

      if (default_proc = variables.default_proc)
        remapped.default_proc = default_proc
      end
      
      remapped
    when Array
      variables.collect do |v|
        variable_stack(v, false)
      end
    else
      force_as_array ? [ variables ] : variables
    end
  end
  
  extend self
end
