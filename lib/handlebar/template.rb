class Handlebar::Template
  # == Constants ============================================================
  
  TOKEN_REGEXP = /((?:[^\{]|\{[^\{]|\{\{\{)+)|\{\{\s*([\&\%\$\.\:\?\*\/\=])?([^\}]*)\}\}/.freeze
  TOKEN_TRIGGER = /\{\{/.freeze

  # == Utility Classes ======================================================
  
  class TemplateHash < Hash; end

  # == Exceptions ===========================================================
  
  class ParseError < Exception ; end
  class ArgumentError < Exception; end
  class MissingVariable < Exception ; end
  class RecursionError < Exception; end

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  
  def initialize(content, options = nil)
    if (options)
      if (method = options[:escape])
        case (method.to_sym)
        when :html, :html_escape
          @escape_method = :html_escape
        when :text, nil
          # Default, ignored
        else
          raise ArgumentError, "Unknown escape method #{method}"
        end
      end
    end
    
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
      variables = nil
      stack = [ [ :base, nil, 0 ] ]
      h = Handlebar::Support
      
      @content.scan(TOKEN_REGEXP).each do |text, tag_type, tag|
        if (text)
          text = text.sub(/\{(\{\{+)/, '\1').sub(/\}(\}\}+)/, '\1')
          
          method << "r<<#{text.inspect};"
        else
          tag = tag.strip
          
          case (tag_type)
          when ?&
            # HTML escaped
            method << "v&&r<<h.html_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?%
            # URI escaped
            method << "v&&r<<h.uri_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?$
            # JavaScript escaped
            method << "v&&r<<h.js_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?.
            # CSS escaped
            method << "v&&r<<h.css_escape(v[#{tag.to_sym.inspect}].to_s);"
          when ?:
            # Defines start of a :section
            variables ||= 's=[];'
            stack << [ :section, tag, 0 ]
            method << "if(v);s<<v;v=v.is_a?(Hash)&&v[#{tag.to_sym.inspect}];"
            method << "h.iterate(v){|v|;v=h.cast_as_vars(v, s);"
          when ??
            # Defines start of a ?conditional
            stack << [ :conditional, tag ]
            method << "if(v&&v.is_a?(Hash)&&v[#{tag.to_sym.inspect}]);"
          when ?*
            template = tag.empty? ? nil : tag.to_sym
            method << "_t=t&&t[#{template.inspect}];r<<(_t.respond_to?(:call)?_t.call(v,t):_t.to_s);"
          when ?/
            # Closes out a section or conditional
            closed = stack.pop
            
            case (closed[0])
            when :section
              unless (tag == closed[1] or tag.empty?)
                raise ParseError, "Template contains unexpected {{#{tag}}}, expected {{#{closed[1]}}}"
              end
              
              method << "};v=s.pop;end;"
            when :conditional
              method << "end;"
            when :base
              raise ParseError, "Unexpected {{#{tag}}}, too many tags closed"
            end
          when ?=
            # Literal insertion
            method << "v&&r<<(v.is_a?(Array)?v[#{stack[-1][2]}]:v[#{tag.to_sym.inspect}]).to_s;"

            stack[-1][2] += 1
          else
            # Contextual insertion
            subst = "v.is_a?(Array)?v[#{stack[-1][2]}]:v[#{tag.to_sym.inspect}]"
            
            if (@escape_method)
              method << "v&&r<<h.#{@escape_method}(#{subst}.to_s);"
            else
              method << "v&&r<<(#{subst}).to_s;"
            end
            
            stack[-1][2] += 1
          end
        end
      end
      
      unless (stack.length == 1)
        case (stack[1][0])
        when :section
          raise ParseError, "Unclosed {{:#{stack[1][1]}}} in template"
        when :conditional
          raise ParseError, "Unclosed {{?#{stack[1][1]}}} in template"
        else
          raise ParseError, "Unclosed {{#{stack[1][1]}}} in template"
        end
      end
      
      c = false
      source = "lambda{|v,t|raise RecursionError if(c);c=true;#{variables}r='';#{method}c=false;r}"

      eval(source)
    end
  end
  
  def render(variables = nil, templates = nil, parents = nil)
    variables =
      case (variables)
      when Array
        variables
      when Hash
        Hash[variables.collect { |k, v| [ k.to_sym, v ] }]
      else
        [ variables ]
      end
      
    if (templates)
      # Unless the template options have already been processed, mapping
      # will need to be performed.
      unless (templates.is_a?(TemplateHash))
        templates = TemplateHash[
          templates.collect do |k, v|
            [
              k,
              case (v)
              when Handlebar::Template, Proc, Array
                v
              when TOKEN_TRIGGER
                self.class.new(v, :escape => @escape_method)
              else
                v.to_s
              end
            ]
          end
        ]
      end
    else
      templates = TemplateHash.new
    end
    
    if (parents)
      case (parents)
      when Array
        _parents = parents.dup
        _parent = _parents.shift
        _parent.render(
          variables,
          templates.merge(
            nil => self.to_proc.call(variables, templates)
          ),
          _parents.empty? ? nil : _parents
        )
      when Handlebar::Template, Proc
        parents.render(
          variables,
          templates.merge(
            nil => self.to_proc.call(variables, templates)
          )
        )
      end
    else
      self.to_proc.call(variables, templates)
    end
  end
  alias_method :call, :render
end
