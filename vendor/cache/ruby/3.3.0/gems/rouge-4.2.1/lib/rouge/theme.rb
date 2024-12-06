# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  class Theme
    include Token::Tokens

    class Style < Hash
      def initialize(theme, hsh={})
        super()
        @theme = theme
        merge!(hsh)
      end

      [:fg, :bg].each do |mode|
        define_method mode do
          return self[mode] unless @theme
          @theme.palette(self[mode]) if self[mode]
        end
      end

      def render(selector, &b)
        return enum_for(:render, selector).to_a.join("\n") unless b

        return if empty?

        yield "#{selector} {"
        rendered_rules.each do |rule|
          yield "  #{rule};"
        end
        yield "}"
      end

      def rendered_rules(&b)
        return enum_for(:rendered_rules) unless b
        yield "color: #{fg}" if fg
        yield "background-color: #{bg}" if bg
        yield "font-weight: bold" if self[:bold]
        yield "font-style: italic" if self[:italic]
        yield "text-decoration: underline" if self[:underline]

        (self[:rules] || []).each(&b)
      end
    end

    def styles
      @styles ||= self.class.styles.dup
    end

    @palette = {}
    def self.palette(arg={})
      @palette ||= InheritableHash.new(superclass.palette)

      if arg.is_a? Hash
        @palette.merge! arg
        @palette
      else
        case arg
        when /#[0-9a-f]+/i
          arg
        else
          @palette[arg] or raise "not in palette: #{arg.inspect}"
        end
      end
    end

    def palette(*a) self.class.palette(*a) end

    @styles = {}
    def self.styles
      @styles ||= InheritableHash.new(superclass.styles)
    end

    def self.render(opts={}, &b)
      new(opts).render(&b)
    end

    def get_own_style(token)
      self.class.get_own_style(token)
    end

    def get_style(token)
      self.class.get_style(token)
    end

    def name
      self.class.name
    end

    class << self
      def style(*tokens)
        style = tokens.last.is_a?(Hash) ? tokens.pop : {}

        tokens.each do |tok|
          styles[tok] = style
        end
      end

      def get_own_style(token)
        token.token_chain.reverse_each do |anc|
          return Style.new(self, styles[anc]) if styles[anc]
        end

        nil
      end

      def get_style(token)
        get_own_style(token) || base_style
      end

      def base_style
        get_own_style(Token::Tokens::Text)
      end

      def name(n=nil)
        return @name if n.nil?

        @name = n.to_s
        register(@name)
      end

      def register(name)
        Theme.registry[name.to_s] = self
      end

      def find(n)
        registry[n.to_s]
      end

      def registry
        @registry ||= {}
      end
    end
  end

  module HasModes
    def mode(arg=:absent)
      return @mode if arg == :absent

      @modes ||= {}
      @modes[arg] ||= get_mode(arg)
    end

    def get_mode(mode)
      return self if self.mode == mode

      new_name = "#{self.name}.#{mode}"
      Class.new(self) { name(new_name); set_mode!(mode) }
    end

    def set_mode!(mode)
      @mode = mode
      send("make_#{mode}!")
    end

    def mode!(arg)
      alt_name = "#{self.name}.#{arg}"
      register(alt_name)
      set_mode!(arg)
    end
  end

  class CSSTheme < Theme
    def initialize(opts={})
      @scope = opts[:scope] || '.highlight'
    end

    def render(&b)
      return enum_for(:render).to_a.join("\n") unless b

      # shared styles for tableized line numbers
      yield "#{@scope} table td { padding: 5px; }"
      yield "#{@scope} table pre { margin: 0; }"

      styles.each do |tok, style|
        Style.new(self, style).render(css_selector(tok), &b)
      end
    end

    def render_base(selector, &b)
      self.class.base_style.render(selector, &b)
    end

    def style_for(tok)
      self.class.get_style(tok)
    end

  private
    def css_selector(token)
      inflate_token(token).map do |tok|
        raise "unknown token: #{tok.inspect}" if tok.shortname.nil?

        single_css_selector(tok)
      end.join(', ')
    end

    def single_css_selector(token)
      return @scope if token == Text

      "#{@scope} .#{token.shortname}"
    end

    # yield all of the tokens that should be styled the same
    # as the given token.  Essentially this recursively all of
    # the subtokens, except those which are more specifically
    # styled.
    def inflate_token(tok, &b)
      return enum_for(:inflate_token, tok) unless block_given?

      yield tok
      tok.sub_tokens.each do |(_, st)|
        next if styles[st]

        inflate_token(st, &b)
      end
    end
  end
end
