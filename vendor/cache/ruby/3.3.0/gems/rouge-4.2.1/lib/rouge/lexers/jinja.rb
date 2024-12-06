# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Jinja < TemplateLexer
      title "Jinja"
      desc "Django/Jinja template engine (jinja.pocoo.org)"

      tag 'jinja'
      aliases 'django'

      mimetypes 'application/x-django-templating', 'application/x-jinja',
                'text/html+django', 'text/html+jinja'

      def self.keywords
        @keywords ||= %w(as context do else extends from ignore missing
                         import include reversed recursive scoped
                         autoescape endautoescape block endblock call endcall
                         filter endfilter for endfor if endif macro endmacro
                         set endset trans endtrans with endwith without)
      end

      def self.tests
        @tests ||= %w(callable defined divisibleby equalto escaped even iterable
                      lower mapping none number odd sameas sequence string
                      undefined upper)
      end

      def self.pseudo_keywords
        @pseudo_keywords ||= %w(true false none True False None)
      end

      def self.word_operators
        @word_operators ||= %w(is in and or not)
      end

      state :root do
        # Comments
        rule %r/{#/, Comment, :comment
        rule %r/##.*/, Comment

        # Raw and verbatim
        rule %r/({%-?)(\s*)(raw|verbatim)(\s*)(-?%})/ do |m|
          groups Comment::Preproc, Text, Keyword, Text, Comment::Preproc
          case m[3]
          when "raw"
            push :raw
          when "verbatim"
            push :verbatim
          end
        end

        # Statements
        rule %r/\{\%/ do
          token Comment::Preproc
          push :statement
        end

        # Expressions
        rule %r/\{\{/ do
          token Comment::Preproc
          push :expression
        end

        rule(/(.+?)(?=\\|{{|{%|{#|##)/m) { delegate parent }
        rule(/.+/m) { delegate parent }
      end

      state :filter do
        # Filters are called like variable|foo(arg1, ...)
        rule %r/(\|\s*)(\w+)/ do
          groups Operator, Name::Function
        end
      end

      state :function do
        rule %r/(\w+)(\()/ do
          groups Name::Function, Punctuation
        end
      end

      state :text do
        rule %r/\s+/m, Text
      end

      state :literal do
        # Strings
        rule %r/"(\\.|.)*?"/, Str::Double
        rule %r/'(\\.|.)*?'/, Str::Single

        # Numbers
        rule %r/\d+(?=}\s)/, Num

        # Arithmetic operators (+, -, *, **, //, /)
        # TODO : implement modulo (%)
        rule %r/(\+|\-|\*|\/\/?|\*\*?|=)/, Operator

        # Comparisons operators (<=, <, >=, >, ==, ===, !=)
        rule %r/(<=?|>=?|===?|!=)/, Operator

        # Punctuation (the comma, [], ())
        rule %r/,/,  Punctuation
        rule %r/\[/, Punctuation
        rule %r/\]/, Punctuation
        rule %r/\(/, Punctuation
        rule %r/\)/, Punctuation
      end

      state :comment do
        rule %r/[^#]+/m, Comment
        rule(/#}/) { token Comment; pop! }
        rule %r/#/, Comment
      end

      state :expression do
        rule %r/\w+\.?/m, Name::Variable

        mixin :filter
        mixin :function
        mixin :literal
        mixin :text

        rule %r/%}|}}/, Comment::Preproc, :pop!
      end

      state :statement do
        rule %r/(\w+\.?)/ do |m|
          if self.class.keywords.include?(m[0])
            groups Keyword
          elsif self.class.pseudo_keywords.include?(m[0])
            groups Keyword::Pseudo
          elsif self.class.word_operators.include?(m[0])
            groups Operator::Word
          elsif self.class.tests.include?(m[0])
            groups Name::Builtin
          else
            groups Name::Variable
          end
        end

        mixin :filter
        mixin :function
        mixin :literal
        mixin :text

        rule %r/\%\}/, Comment::Preproc, :pop!
      end

      state :raw do
        rule %r/({%-?)(\s*)(endraw)(\s*)(-?%})/ do
          groups Comment::Preproc, Text, Keyword, Text, Comment::Preproc
          pop!
        end
        rule %r/[^{]+/, Text
        rule %r/{/, Text
      end

      state :verbatim do
        rule %r/({%-?)(\s*)(endverbatim)(\s*)(-?%})/ do
          groups Comment::Preproc, Text, Keyword, Text, Comment::Preproc
          pop!
        end
        rule %r/[^{]+/, Text
        rule %r/{/, Text
      end
    end
  end
end
