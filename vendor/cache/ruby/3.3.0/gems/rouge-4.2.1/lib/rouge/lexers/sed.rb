# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Sed < RegexLexer
      title "sed"
      desc 'sed, the ultimate stream editor'

      tag 'sed'
      filenames '*.sed'
      mimetypes 'text/x-sed'

      def self.detect?(text)
        return true if text.shebang? 'sed'
      end

      class Regex < RegexLexer
        state :root do
          rule %r/\\./, Str::Escape
          rule %r/\[/, Punctuation, :brackets
          rule %r/[$^.*]/, Operator
          rule %r/[()]/, Punctuation
          rule %r/./, Str::Regex
        end

        state :brackets do
          rule %r/\^/ do
            token Punctuation
            goto :brackets_int
          end

          rule(//) { goto :brackets_int }
        end

        state :brackets_int do
          # ranges
          rule %r/.-./, Name::Variable
          rule %r/\]/, Punctuation, :pop!
          rule %r/./, Str::Regex
        end
      end

      class Replacement < RegexLexer
        state :root do
          rule %r/\\./m, Str::Escape
          rule %r/&/, Operator
          rule %r/[^\\&]+/m, Text
        end
      end

      def regex
        @regex ||= Regex.new(options)
      end

      def replacement
        @replacement ||= Replacement.new(options)
      end

      start { regex.reset!; replacement.reset! }

      state :whitespace do
        rule %r/\s+/m, Text
        rule(/#.*?\n/) { token Comment; reset_stack }
        rule(/\n/) { token Text; reset_stack }
        rule(/;/) { token Punctuation; reset_stack }
      end

      state :root do
        mixin :addr_range
      end

      edot = /\\.|./m

      state :command do
        mixin :whitespace

        # subst and transliteration
        rule %r/(s)(.)(#{edot}*?)(\2)(#{edot}*?)(\2)/m do |m|
          token Keyword, m[1]
          token Punctuation, m[2]
          delegate regex, m[3]
          token Punctuation, m[4]
          delegate replacement, m[5]
          token Punctuation, m[6]


          goto :flags
        end

        rule %r/(y)(.)(#{edot}*?)(\2)(#{edot}*?)(\2)/m do |m|
          token Keyword, m[1]
          token Punctuation, m[2]
          delegate replacement, m[3]
          token Punctuation, m[4]
          delegate replacement, m[5]
          token Punctuation, m[6]

          pop!
        end

        # commands that take a text segment as an argument
        rule %r/([aic])(\s*)/ do
          groups Keyword, Text; goto :text
        end

        rule %r/[pd]/, Keyword

        # commands that take a number argument
        rule %r/([qQl])(\s+)(\d+)/i do
          groups Keyword, Text, Num
          pop!
        end

        # no-argument commands
        rule %r/[={}dDgGhHlnpPqx]/, Keyword, :pop!

        # commands that take a filename argument
        rule %r/([rRwW])(\s+)(\S+)/ do
          groups Keyword, Text, Name
          pop!
        end

        # commands that take a label argument
        rule %r/([:btT])(\s+)(\S+)/ do
          groups Keyword, Text, Name::Label
          pop!
        end
      end

      state :addr_range do
        mixin :whitespace

        ### address ranges ###
        addr_tok = Keyword::Namespace
        rule %r/\d+/, addr_tok
        rule %r/[$,~+!]/, addr_tok

        rule %r((/)((?:\\.|.)*?)(/)) do |m|
          token addr_tok, m[1]; delegate regex, m[2]; token addr_tok, m[3]
        end

        # alternate regex rage delimiters
        rule %r((\\)(.)((?:\\.|.)*?)(\2)) do |m|
          token addr_tok, m[1] + m[2]
          delegate regex, m[3]
          token addr_tok, m[4]
        end

        rule(//) { push :command }
      end

      state :text do
        rule %r/[^\\\n]+/, Str
        rule %r/\\\n/, Str::Escape
        rule %r/\\/, Str
        rule %r/\n/, Text, :pop!
      end

      state :flags do
        rule %r/[gp]+/, Keyword, :pop!

        # writing to a file with the subst command.
        # who'da thunk...?
        rule %r/([wW])(\s+)(\S+)/ do
          token Keyword; token Text; token Name
        end

        rule(//) { pop! }
      end
    end
  end
end
