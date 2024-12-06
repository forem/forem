# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # A lexer for the Slim tempalte language
    # @see http://slim-lang.org
    class Slim < RegexLexer
      include Indentation

      title "Slim"
      desc 'The Slim template language'

      tag 'slim'

      filenames '*.slim'

      # Ruby identifier characters
      ruby_chars = /[\w\!\?\@\$]/

      # Since you are allowed to wrap lines with a backslash, include \\\n in characters
      dot = /(\\\n|.)/

      def ruby
        @ruby ||= Ruby.new(options)
      end

      def html
        @html ||= HTML.new(options)
      end

      def filters
        @filters ||= {
          'ruby' => ruby,
          'erb' => ERB.new(options),
          'javascript' => Javascript.new(options),
          'css' => CSS.new(options),
          'coffee' => Coffeescript.new(options),
          'markdown' => Markdown.new(options),
          'scss' => Scss.new(options),
          'sass' => Sass.new(options)
        }
      end

      start { ruby.reset!; html.reset! }

      state :root do
        rule %r/\s*\n/, Text
        rule(/\s*/) { |m| token Text; indentation(m[0]) }
      end

      state :content do
        mixin :css

        rule %r/\/#{dot}*/, Comment, :indented_block

        rule %r/(doctype)(\s+)(.*)/ do
          groups Name::Namespace, Text::Whitespace, Text
          pop!
        end

        # filters, shamelessly ripped from HAML
        rule %r/(\w*):\s*\n/ do |m|
          token Name::Decorator
          pop!
          starts_block :filter_block

          filter_name = m[1].strip

          @filter_lexer = self.filters[filter_name]
          @filter_lexer.reset! unless @filter_lexer.nil?

          puts "    slim: filter #{filter_name.inspect} #{@filter_lexer.inspect}" if @debug
        end

        # Text
        rule %r([\|'](?=\s)) do
          token Punctuation
          pop!
          starts_block :plain_block
          goto :plain_block
        end

        rule %r/-|==|=/, Punctuation, :ruby_line

        # Dynamic tags
        rule %r/(\*)(#{ruby_chars}+\(.*?\))/ do |m|
          token Punctuation, m[1]
          delegate ruby, m[2]
          push :tag
        end

        rule %r/(\*)(#{ruby_chars}+)/ do |m|
          token Punctuation, m[1]
          delegate ruby, m[2]
          push :tag
        end

        #rule %r/<\w+(?=.*>)/, Keyword::Constant, :tag # Maybe do this, look ahead and stuff
        rule %r((</?[\w\s\=\'\"]+?/?>)) do |m| # Dirty html
          delegate html, m[1]
          pop!
        end

        # Ordinary slim tags
        rule %r/\w+/, Name::Tag, :tag

      end

      state :tag do
        mixin :css
        mixin :indented_block
        mixin :interpolation

        # Whitespace control
        rule %r/[<>]/, Punctuation

        # Trim whitespace
        rule %r/\s+?/, Text::Whitespace

        # Splats, these two might be mergable?
        rule %r/(\*)(#{ruby_chars}+)/ do |m|
          token Punctuation, m[1]
          delegate ruby, m[2]
        end

        rule %r/(\*)(\{#{dot}+?\})/ do |m|
          token Punctuation, m[1]
          delegate ruby, m[2]
        end

        # Attributes
        rule %r/([\w\-]+)(\s*)(\=)/ do |m|
          token Name::Attribute, m[1]
          token Text::Whitespace, m[2]
          token Punctuation, m[3]
          push :html_attr
        end

        # Ruby value
        rule %r/(\=)(#{dot}+)/ do |m|
          token Punctuation, m[1]
          #token Keyword::Constant, m[2]
          delegate ruby, m[2]
        end

        # HTML Entities
        rule(/&\S*?;/, Name::Entity)

        rule %r/#{dot}+?/, Text

        rule %r/\s*\n/, Text::Whitespace, :pop!
      end

      state :css do
        rule(/\.[\w-]*/) { token Name::Class; goto :tag }
        rule(/#[a-zA-Z][\w:-]*/) { token Name::Function; goto :tag }
      end

      state :html_attr do
        # Strings, double/single quoted
        rule(/\s*(['"])#{dot}*?\1/, Literal::String, :pop!)

        # Ruby stuff
        rule(/(#{ruby_chars}+\(.*?\))/) { |m| delegate ruby, m[1]; pop! }
        rule(/(#{ruby_chars}+)/) { |m| delegate ruby, m[1]; pop! }

        rule %r/\s+/, Text::Whitespace
      end

      state :ruby_line do
        # Need at top
        mixin :indented_block

        rule(/[,\\]\s*\n/) { delegate ruby }
        rule %r/[ ]\|[ \t]*\n/, Str::Escape
        rule(/.*?(?=([,\\]$| \|)?[ \t]*$)/) { delegate ruby }
      end

      state :filter_block do
        rule %r/([^#\n]|#[^{\n]|(\\\\)*\\#\{)+/ do
          if @filter_lexer
            delegate @filter_lexer
          else
            token Name::Decorator
          end
        end

        mixin :interpolation
        mixin :indented_block
      end

      state :plain_block do
        mixin :interpolation

        rule %r((</?[\w\s\=\'\"]+?/?>)) do |m| # Dirty html
          delegate html, m[1]
        end

        # HTML Entities
        rule(/&\S*?;/, Name::Entity)

        #rule %r/([^#\n]|#[^{\n]|(\\\\)*\\#\{)+/ do
        rule %r/#{dot}+?/, Text

        mixin :indented_block
      end

      state :interpolation do
        rule %r/#[{]/, Str::Interpol, :ruby_interp
      end

      state :ruby_interp do
        rule %r/[}]/, Str::Interpol, :pop!
        mixin :ruby_interp_inner
      end

      state :ruby_interp_inner do
        rule(/[{]/) { delegate ruby; push :ruby_interp_inner }
        rule(/[}]/) { delegate ruby; pop! }
        rule(/[^{}]+/) { delegate ruby }
      end

      state :indented_block do
        rule(/(?<!\\)\n/) { token Text; reset_stack }
      end
    end
  end
end
