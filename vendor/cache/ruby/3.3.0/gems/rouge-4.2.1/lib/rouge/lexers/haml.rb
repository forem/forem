# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # A lexer for the Haml templating system for Ruby.
    # @see http://haml.info
    class Haml < RegexLexer
      include Indentation

      title "Haml"
      desc "The Haml templating system for Ruby (haml.info)"

      tag 'haml'
      aliases 'HAML'

      filenames '*.haml'
      mimetypes 'text/x-haml'

      option 'filters[filter_name]', 'Mapping of lexers to use for haml :filters'
      attr_reader :filters
      # @option opts :filters
      #   A hash of filter name to lexer of how various filters should be
      #   highlighted.  By default, :javascript, :css, :ruby, and :erb
      #   are supported.
      def initialize(opts={})
        super

        default_filters = {
          'javascript' => Javascript.new(options),
          'css' => CSS.new(options),
          'ruby' => ruby,
          'erb' => ERB.new(options),
          'markdown' => Markdown.new(options),
          'sass' => Sass.new(options),
          # TODO
          # 'textile' => Textile.new(options),
          # 'maruku' => Maruku.new(options),
        }

        @filters = hash_option(:filters, default_filters) do |v|
          as_lexer(v) || PlainText.new(@options)
        end
      end

      def ruby
        @ruby ||= Ruby.new(@options)
      end

      def html
        @html ||= HTML.new(@options)
      end

      def ruby!(state)
        ruby.reset!
        push state
      end

      start { ruby.reset!; html.reset! }

      identifier = /[\w:-]+/
      ruby_var = /[a-z]\w*/

      # Haml can include " |\n" anywhere,
      # which is ignored and used to wrap long lines.
      # To accomodate this, use this custom faux dot instead.
      dot = /[ ]\|\n(?=.*[ ]\|)|./

      state :root do
        rule %r/\s*\n/, Text
        rule(/\s*/) { |m| token Text; indentation(m[0]) }
      end

      state :content do
        mixin :css
        rule(/%#{identifier}/) { token Name::Tag; goto :tag }
        rule %r/!!!#{dot}*\n/, Name::Namespace, :pop!
        rule %r(
          (/) (\[#{dot}*?\]) (#{dot}*\n)
        )x do
          groups Comment, Comment::Special, Comment
          pop!
        end

        rule %r(/#{dot}*\n) do
          token Comment
          pop!
          starts_block :html_comment_block
        end

        rule %r/-##{dot}*\n/ do
          token Comment
          pop!
          starts_block :haml_comment_block
        end

        rule %r/-/ do
          token Punctuation
          reset_stack
          ruby! :ruby_line
        end

        # filters
        rule %r/:(#{dot}*)\n/ do |m|
          token Name::Decorator
          pop!
          starts_block :filter_block

          filter_name = m[1].strip

          @filter_lexer = self.filters[filter_name]
          @filter_lexer.reset! unless @filter_lexer.nil?

          puts "    haml: filter #{filter_name.inspect} #{@filter_lexer.inspect}" if @debug
        end

        mixin :eval_or_plain
      end

      state :css do
        rule(/\.#{identifier}/) { token Name::Class; goto :tag }
        rule(/##{identifier}/) { token Name::Function; goto :tag }
      end

      state :tag do
        mixin :css
        rule(/[{]/) { token Punctuation; ruby! :ruby_tag }
        rule(/\[#{dot}*?\]/) { delegate ruby }

        rule %r/\(/, Punctuation, :html_attributes
        rule %r/\s*\n/, Text, :pop!

        # whitespace chompers
        rule %r/[<>]{1,2}(?=[ \t=])/, Punctuation

        mixin :eval_or_plain
      end

      state :plain do
        rule(/([^#\n]|#[^{\n]|(\\\\)*\\#\{)+/) { delegate html }
        mixin :interpolation
        rule(/\n/) { token Text; reset_stack }
      end

      state :eval_or_plain do
        rule %r/[&!]?==/, Punctuation, :plain
        rule %r/[&!]?[=!]/ do
          token Punctuation
          reset_stack
          ruby! :ruby_line
        end

        rule(//) { push :plain }
      end

      state :ruby_line do
        rule %r/\n/, Text, :pop!
        rule(/,[ \t]*\n/) { delegate ruby }
        rule %r/[ ]\|[ \t]*\n/, Str::Escape
        rule(/.*?(?=(,$| \|)?[ \t]*$)/) { delegate ruby }
      end

      state :ruby_tag do
        mixin :ruby_inner
      end

      state :html_attributes do
        rule %r/\s+/, Text
        rule %r/#{identifier}\s*=/, Name::Attribute, :html_attribute_value
        rule identifier, Name::Attribute
        rule %r/\)/, Text, :pop!
      end

      state :html_attribute_value do
        rule %r/\s+/, Text
        rule ruby_var, Name::Variable, :pop!
        rule %r/@#{ruby_var}/, Name::Variable::Instance, :pop!
        rule %r/\$#{ruby_var}/, Name::Variable::Global, :pop!
        rule %r/'(\\\\|\\'|[^'\n])*'/, Str, :pop!
        rule %r/"(\\\\|\\"|[^"\n])*"/, Str, :pop!
      end

      state :html_comment_block do
        rule %r/#{dot}+/, Comment
        mixin :indented_block
      end

      state :haml_comment_block do
        rule %r/#{dot}+/, Comment::Preproc
        mixin :indented_block
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

      state :interpolation do
        rule %r/#[{]/, Str::Interpol, :ruby
      end

      state :ruby do
        rule %r/[}]/, Str::Interpol, :pop!
        mixin :ruby_inner
      end

      state :ruby_inner do
        rule(/[{]/) { delegate ruby; push :ruby_inner }
        rule(/[}]/) { delegate ruby; pop! }
        rule(/[^{}]+/) { delegate ruby }
      end

      state :indented_block do
        rule(/\n/) { token Text; reset_stack }
      end
    end
  end
end
