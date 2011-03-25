class Handlebar::Template
  # == Constants ============================================================
  
  TOKEN_REGEXP = /((?:[^\{]|\{[^\{]|\{\{\{)+)|\{\{([^\}]*)\}\}/

  # == Exceptions ===========================================================
  
  class ParseError < Exception ; end
  class MissingVariable < Exception ; end

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  
  def initialize(content, context = nil)
    @context = context
    @content =
      case (content)
      when IO
        content.read
      else
        content.to_s
      end
  end
  
  def to_proc
    @proc ||= begin
      method = ''
      stackvar = nil
      stack = [ :base, nil, 0 ]
      h = Handlebar::Support
      
      @content.scan(TOKEN_REGEXP).each do |text, tag|
        if (text)
          text = text.sub(/\{(\{\{+)/, '\1').sub(/\}(\}\}+)/, '\1')
          
          method << "r<<#{text.inspect};"
        else
          tag = tag.sub(/^\s+/, '').sub(/\s+$/, '')
          
          case (tag[0])
          when ?&
            tag = tag[1, tag.length]
            method << "v&&r<<h.html_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?%
            tag = tag[1, tag.length]
            method << "v&&r<<h.uri_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?$
            tag = tag[1, tag.length]
            method << "v&&r<<h.js_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?:
            stackvar ||= 's=[];'
            tag = tag[1, tag.length]
            stack << [ :section, tag, 0 ]
            method << "if(v);s<<v;v=v.is_a?(Hash)&&v[#{tag.to_sym.inspect}];"
            method << "h.iterate(v){|v|;v=h.cast_as_vars(v);"
          when ??
            tag = tag[1, tag.length]
            stack << [ :conditional, tag ]
            method << "if(v&&v.is_a?(Hash)&&v[#{tag.to_sym.inspect}]);"
          when ?/
            closed = stack.pop
            
            case (closed[0])
            when :section
              method << "};v=s.pop;end;"
            when :conditional
              method << "end;"
            when :base
              raise ParseError, "Too many tags closed"
            end
          when ?=
            tag = tag[1, tag.length]
            method << "v&&r<<(v.is_a?(Array)?v[#{stack[2]}]:v[#{tag.to_sym.inspect}]).to_s;"

            stack[2] += 1
          else
            if (@context)
              method << "v&&r<<h.#{@context}_escape((v.is_a?(Array)?v[#{stack[2]}]:v[#{tag.to_sym.inspect}]).to_s);"
            else
              method << "v&&r<<(v.is_a?(Array)?v[#{stack[2]}]:v[#{tag.to_sym.inspect}]).to_s;"
            end
            
            stack[2] += 1
          end
        end
      end
      
      method = "lambda{|v|#{stackvar}r='';#{method}}"

      eval(method)
    end
  end
  
  def interpret(variables = nil)
    variables =
      case (variables)
      when Array
        variables
      when Hash
        Hash[variables.collect { |k, v| [ k.to_sym, v ] }]
      else
        [ variables ]
      end
    
    self.to_proc.call(variables)
  end
end
