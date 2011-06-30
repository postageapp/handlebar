class Handlebar::Template
  # == Constants ============================================================
  
  TOKEN_REGEXP = /((?:[^\{]|\{[^\{]|\{\{\{)+)|\{\{\s*([\&\%\$\.\:\?\*\/\=])?([^\}]*)\}\}/.freeze
  TOKEN_TRIGGER = /\{\{/.freeze

  # == Utility Classes ======================================================
  
  class TemplateHash < Hash; end

  class VariableTracker < Hash
    def initialize
      super do |h, k|
        h[k] = h.length
      end
    end
  end

  # == Exceptions ===========================================================
  
  class ParseError < Exception ; end
  class ArgumentError < Exception; end
  class MissingVariable < Exception ; end
  class RecursionError < Exception; end

  # == Class Methods ========================================================

  # == Instance Methods =====================================================
  
  def initialize(content, options = nil)
    if (options)
      if (source = options[:escape])
        case (source.to_sym)
        when :html, :html_escape
          @escape_method = :html_escape
        when :text, nil
          # Default, ignored
        else
          raise ArgumentError, "Unknown escape source #{source}"
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
    @_proc ||= begin
      source = ''

      self.compile(:source => source, :escape_method => @escape_method)

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

  def compile(options)
    escape_method = options[:escape_method]
    sections = options[:sections]
    templates = options[:templates]
    variables = options[:variables]
    source = options[:source]

    stack = [ [ :base, nil, VariableTracker.new ] ]
    stack_variables = nil
    
    @content.scan(TOKEN_REGEXP).each do |text, tag_type, tag|
      if (text)
        text = text.sub(/\{(\{\{+)/, '\1').sub(/\}(\}\}+)/, '\1')
        
        source and source << "r<<#{text.inspect};"
      else
        tag = tag.strip
        tag = tag.empty? ? nil : tag.to_sym
        
        case (tag_type)
        when ?&
          # HTML escaped
          index = stack[-1][2][tag.inspect]

          source and source << "v&&r<<h.html_escape(v[#{tag.inspect}].to_s);"
          
          variables and variables[tag] = true

        when ?%
          # URI escaped
          index = stack[-1][2][tag.inspect]

          source and source << "v&&r<<h.uri_escape(v.is_a?(Array)?v[#{index}]:v[#{tag.inspect}]);"

          variables and variables[tag] = true
        when ?$
          # JavaScript escaped
          index = stack[-1][2][tag.inspect]

          source and source << "v&&r<<h.js_escape(v.is_a?(Array)?v[#{index}]:v[#{tag.inspect}]);"

          variables and variables[tag] = true
        when ?.
          # CSS escaped
          index = stack[-1][2][tag.inspect]

          source and source << "v&&r<<h.css_escape(v.is_a?(Array)?v[#{index}]:v[#{tag.inspect}]);"

          variables and variables[tag] = true
        when ?:
          # Defines start of a :section
          index = stack[-1][2][tag.inspect]

          stack_variables ||= 's=[];'
          stack << [ :section, tag, VariableTracker.new ]

          source and source << "if(v);s<<v;v=v.is_a?(Array)?v[#{index}]:(v.is_a?(Hash)&&v[#{tag.inspect}]);"
          source and source << "h.iterate(v){|v|;v=h.cast_as_vars(v, s);"
          
          sections and sections[tag] = true
        when ??
          # Defines start of a ?conditional
          
          stack[-1][2][tag.inspect]

          # The stack will inherit the variable assignment locations from the
          # existing stack layer.
          stack << [ :conditional, tag, stack[-1][2] ]
          source and source << "if(v&&v.is_a?(Hash)&&v[#{tag.inspect}]);"

          variables and variables[tag] = true
        when ?*
          source and source << "_t=t&&t[#{tag.inspect}];r<<(_t.respond_to?(:call)?_t.call(v,t):_t.to_s);"
          
          templates and templates[tag] = true
        when ?/
          # Closes out a section or conditional
          closed = stack.pop
          
          case (closed[0])
          when :section
            if (tag and tag != closed[1])
              raise ParseError, "Template contains unexpected {{#{tag}}}, expected {{#{closed[1]}}}"
            end
            
            source and source << "};v=s.pop;end;"
          when :conditional
            source and source << "end;"
          when :base
            raise ParseError, "Unexpected {{#{tag}}}, too many tags closed"
          end
        when ?=
          # Literal insertion
          index = stack[-1][2][tag.inspect]

          source and source << "v&&r<<(v.is_a?(Array)?v[#{index}]:v[#{tag.inspect}]).to_s;"

          variables and variables[tag] = true
        else
          # Contextual insertion
          index = stack[-1][2][tag.inspect]

          subst = "v.is_a?(Array)?v[#{stack[-1][2][tag.inspect]}]:v[#{tag.inspect}]"
          
          if (escape_method)
            source and source << "v&&r<<h.#{escape_method}(#{subst}.to_s);"
          else
            source and source << "v&&r<<(#{subst}).to_s;"
          end

          variables and variables[tag] = true
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
    
    if (source)
      source.replace("begin;c=false;h=Handlebar::Support;lambda{|v,t|raise RecursionError if(c);c=true;#{stack_variables}r='';#{source}c=false;r};end")
    end
    
    true
  end
  
  def to_yaml(dump)
    _proc, @_proc = @_proc, nil
    
    super(dump)
    
    @_proc = _proc
    
    dump
  end
    
  def marshal_dump
    [ @content, { :escape => @escape_method } ]
  end
  
  def marshal_load(dump)
    @content, options = dump
    
    @escape_method = options[:escape]
  end
end
