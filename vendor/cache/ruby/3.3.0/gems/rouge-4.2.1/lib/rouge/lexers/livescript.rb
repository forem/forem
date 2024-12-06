# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Livescript < RegexLexer
      tag 'livescript'
      aliases 'ls'
      filenames '*.ls'
      mimetypes 'text/livescript'

      title 'LiveScript'
      desc 'LiveScript, a language which compiles to JavaScript (livescript.net)'

      def self.detect?(text)
        return text.shebang? 'lsc'
      end

      def self.declarations
        @declarations ||= Set.new %w(const let var function class extends implements)
      end

      def self.keywords
        @keywords ||= Set.new %w(
          loop until for in of while break return continue switch case
          fallthrough default otherwise when then if unless else throw try
          catch finally new delete typeof instanceof super by from to til
          with require do debugger import export yield
        )
      end

      def self.constants
        @constants ||= Javascript.constants + %w(yes no on off void)
      end

      def self.builtins
        @builtins ||= Javascript.builtins + %w(this it that arguments)
      end

      def self.loop_control_keywords
        @loop_control_keywords ||= Set.new %w(break continue)
      end

      id = /[$a-z_]((-(?=[a-z]))?[a-z0-9_])*/i
      int_number = /\d[\d_]*/
      int = /#{int_number}(e[+-]?#{int_number})?[$\w]*/ # the last class matches units

      state :root do
        rule(%r(^(?=\s|/))) { push :slash_starts_regex }
        mixin :comments
        mixin :whitespace

        # list of words
        rule %r/(<\[)(.*?)(\]>)/m do
          groups Punctuation, Str, Punctuation
        end

        # function declarations
        rule %r/!\s*function\b/, Keyword::Declaration
        rule %r/!?[-~]>|<[-~]!?/, Keyword::Declaration

        # switch arrow
        rule %r/(=>)/, Keyword

        # prototype attributes
        rule %r/(::)(#{id})/ do
          groups Punctuation, Name::Attribute
          push :id
        end
        rule %r/(::)(#{int})/ do
          groups Punctuation, Num::Integer
          push :id
        end

        # instance attributes
        rule %r/(@)(#{id})/ do
          groups Name::Variable::Instance, Name::Attribute
          push :id
        end
        rule %r/([.])(#{id})/ do
          groups Punctuation, Name::Attribute
          push :id
        end
        rule %r/([.])(\d+)/ do
          groups Punctuation, Num::Integer
          push :id
        end
        rule %r/#{id}(?=\s*:[^:=])/, Name::Attribute

        # operators
        rule %r(
          [+][+]|--|&&|\b(and|x?or|is(nt)?|not)\b(?!-[a-zA-Z]|_)|[|][|]|
          [.]([|&^]|<<|>>>?)[.]|\\(?=\n)|[.:]=|<<<<?|<[|]|[|]>|
          (<<|>>|==?|!=?|[-<>+*%^/~?])=?
        )x, Operator, :slash_starts_regex

        # arguments shorthand
        rule %r/(&)(#{id})?/ do
          groups Name::Builtin, Name::Attribute
        end

        # switch case
        rule %r/[|]|\bcase(?=\s)/, Keyword, :switch_underscore

        rule %r/@/, Name::Variable::Instance
        rule %r/[.]{3}/, Punctuation
        rule %r/:/, Punctuation

        # keywords
        rule %r/#{id}/ do |m|
          if self.class.loop_control_keywords.include? m[0]
            token Keyword
            push :loop_control
            next
          elsif self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.constants.include? m[0]
            token Name::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
          elsif /^[A-Z]/.match(m[0]) && /[^-][a-z]/.match(m[0])
            token Name::Class
          else
            token Name::Variable
          end
          push :id
        end

        # punctuation and brackets
        rule %r/\](?=[!?.]|#{id})/, Punctuation, :id
        rule %r/[{(\[;,]/, Punctuation, :slash_starts_regex
        rule %r/[})\].]/, Punctuation

        # literals
        rule %r/#{int_number}[.]#{int}/, Num::Float
        rule %r/0x[0-9A-Fa-f]+/, Num::Hex
        rule %r/#{int}/, Num::Integer

        # strings
        rule %r/"""/ do
          token Str
          push do
            rule %r/"""/, Str, :pop!
            rule %r/"/, Str
            mixin :double_strings
          end
        end

        rule %r/'''/ do
          token Str
          push do
            rule %r/'''/, Str, :pop!
            rule %r/'/, Str
            mixin :single_strings
          end
        end

        rule %r/"/ do
          token Str
          push do
            rule %r/"/, Str, :pop!
            mixin :double_strings
          end
        end

        rule %r/'/ do
          token Str
          push do
            rule %r/'/, Str, :pop!
            mixin :single_strings
          end
        end

        # words
        rule %r/\\\S[^\s,;\])}]*/, Str
      end

      state :code_escape do
        rule %r(\\(
          c[A-Z]|
          x[0-9a-fA-F]{2}|
          u[0-9a-fA-F]{4}|
          u\{[0-9a-fA-F]{4}\}
        ))x, Str::Escape
      end

      state :interpolated_expression do
        rule %r/}/, Str::Interpol, :pop!
        mixin :root
      end

      state :interpolation do
        # with curly braces
        rule %r/[#][{]/, Str::Interpol, :interpolated_expression
        # without curly braces
        rule %r/(#)(#{id})/ do |m|
          groups Str::Interpol, (self.class.builtins.include? m[2]) ? Name::Builtin : Name::Variable
        end
      end

      state :whitespace do
        # white space and loop labels
        rule %r/(\s+?)(?:^([^\S\n]*)(:#{id}))?/m do
          groups Text, Text, Name::Label
        end
      end

      state :whitespace_single_line do
        rule %r([^\S\n]+), Text
      end

      state :slash_starts_regex do
        mixin :comments
        mixin :whitespace
        mixin :multiline_regex_begin

        rule %r(
          /(\\.|[^\[/\\\n]|\[(\\.|[^\]\\\n])*\])+/ # a regex
          ([gimy]+\b|\B)
        )x, Str::Regex, :pop!

        rule(//) { pop! }
      end

      state :multiline_regex_begin do
        rule %r(//) do
          token Str::Regex
          goto :multiline_regex
        end
      end

      state :multiline_regex_end do
        rule %r(//([gimy]+\b|\B)), Str::Regex, :pop!
      end

      state :multiline_regex do
        mixin :multiline_regex_end
        mixin :regex_comment
        mixin :interpolation
        mixin :code_escape
        rule %r/\\\D/, Str::Escape
        rule %r/\\\d+/, Name::Variable
        rule %r/./m, Str::Regex
      end

      state :regex_comment do
        rule %r/^#(\s+.*)?$/, Comment::Single
        rule %r/(\s+)(#)(\s+.*)?$/ do
          groups Text, Comment::Single, Comment::Single
        end
      end

      state :comments do
        rule %r(/\*.*?\*/)m, Comment::Multiline
        rule %r/#.*$/, Comment::Single
      end

      state :switch_underscore do
        mixin :whitespace_single_line
        rule %r/_(?=\s*=>|\s+then\b)/, Keyword
        rule(//) { pop! }
      end

      state :loop_control do
        mixin :whitespace_single_line
        rule %r/#{id}(?=[);\n])/, Name::Label
        rule(//) { pop! }
      end

      state :id do
        rule %r/[!?]|[.](?!=)/, Punctuation
        rule %r/[{]/ do
          # destructuring
          token Punctuation
          push do
            rule %r/[,;]/, Punctuation
            rule %r/#{id}/, Name::Attribute
            rule %r/#{int}/, Num::Integer
            mixin :whitespace
            rule %r/[}]/, Punctuation, :pop!
          end
        end
        rule %r/#{id}/, Name::Attribute
        rule %r/#{int}/, Num::Integer
        rule(//) { goto :slash_starts_regex }
      end

      state :strings do
        # all strings are multi-line
        rule %r/[^#\\'"]+/m, Str
        mixin :code_escape
        rule %r/\\./, Str::Escape
        rule %r/#/, Str
      end

      state :double_strings do
        rule %r/'/, Str
        mixin :interpolation
        mixin :strings
      end

      state :single_strings do
        rule %r/"/, Str
        mixin :strings
      end
    end
  end
end
