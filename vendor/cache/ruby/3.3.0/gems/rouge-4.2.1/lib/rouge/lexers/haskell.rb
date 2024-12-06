# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Haskell < RegexLexer
      title "Haskell"
      desc "The Haskell programming language (haskell.org)"

      tag 'haskell'
      aliases 'hs'
      filenames '*.hs', '*.hs-boot'
      mimetypes 'text/x-haskell'

      def self.detect?(text)
        return true if text.shebang?('runhaskell')
      end

      reserved = %w(
        _ case class data default deriving do else if in infix infixl infixr
        instance let newtype of then type where
      )

      ascii = %w(
        NUL SOH [SE]TX EOT ENQ ACK BEL BS HT LF VT FF CR S[OI] DLE
        DC[1-4] NAK SYN ETB CAN EM SUB ESC [FGRU]S SP DEL
      )

      state :basic do
        rule %r/\s+/m, Text
        rule %r/{-#/, Comment::Preproc, :comment_preproc
        rule %r/{-/, Comment::Multiline, :comment
        rule %r/^--\s+\|.*?$/, Comment::Doc
        # this is complicated in order to support custom symbols
        # like -->
        rule %r/--(?![!#\$\%&*+.\/<=>?@\^\|_~]).*?$/, Comment::Single
      end

      # nested commenting
      state :comment do
        rule %r/-}/, Comment::Multiline, :pop!
        rule %r/{-/, Comment::Multiline, :comment
        rule %r/[^-{}]+/, Comment::Multiline
        rule %r/[-{}]/, Comment::Multiline
      end

      state :comment_preproc do
        rule %r/-}/, Comment::Preproc, :pop!
        rule %r/{-/, Comment::Preproc, :comment
        rule %r/[^-{}]+/, Comment::Preproc
        rule %r/[-{}]/, Comment::Preproc
      end

      state :root do
        mixin :basic

        rule %r/'(?=(?:.|\\\S+)')/, Str::Char, :character
        rule %r/"/, Str, :string

        rule %r/\d+e[+-]?\d+/i, Num::Float
        rule %r/\d+\.\d+(e[+-]?\d+)?/i, Num::Float
        rule %r/0o[0-7]+/i, Num::Oct
        rule %r/0x[\da-f]+/i, Num::Hex
        rule %r/\d+/, Num::Integer

        rule %r/[\w']+/ do |m|
          match = m[0]
          if match == "import"
            token Keyword::Reserved
            push :import
          elsif match == "module"
            token Keyword::Reserved
            push :module
          elsif reserved.include?(match)
            token Keyword::Reserved
          elsif match =~ /\A'?[A-Z]/
            token Keyword::Type
          else
            token Name
          end
        end

        # lambda operator
        rule %r(\\(?![:!#\$\%&*+.\\/<=>?@^\|~-]+)), Name::Function
        # special operators
        rule %r((<-|::|->|=>|=)(?![:!#\$\%&*+.\\/<=>?@^\|~-]+)), Operator
        # constructor/type operators
        rule %r(:[:!#\$\%&*+.\\/<=>?@^\|~-]*), Operator
        # other operators
        rule %r([:!#\$\%&*+.\\/<=>?@^\|~-]+), Operator

        rule %r/\[\s*\]/, Keyword::Type
        rule %r/\(\s*\)/, Name::Builtin

        # Quasiquotations
        rule %r/(\[)([_a-z][\w']*)(\|)/ do |m|
          token Operator, m[1]
          token Name, m[2]
          token Operator, m[3]
          push :quasiquotation
        end

        rule %r/[\[\](),;`{}]/, Punctuation
      end

      state :import do
        rule %r/\s+/, Text
        rule %r/"/, Str, :string
        rule %r/\bqualified\b/, Keyword
        # import X as Y
        rule %r/([A-Z][\w.]*)(\s+)(as)(\s+)([A-Z][a-zA-Z0-9_.]*)/ do
          groups(
            Name::Namespace, # X
            Text, Keyword, # as
            Text, Name # Y
          )
          pop!
        end

        # import X hiding (functions)
        rule %r/([A-Z][\w.]*)(\s+)(hiding)(\s+)(\()/ do
          groups(
            Name::Namespace, # X
            Text, Keyword, # hiding
            Text, Punctuation # (
          )
          goto :funclist
        end

        # import X (functions)
        rule %r/([A-Z][\w.]*)(\s+)(\()/ do
          groups(
            Name::Namespace, # X
            Text,
            Punctuation # (
          )
          goto :funclist
        end

        rule %r/[\w.]+/, Name::Namespace, :pop!
      end

      state :module do
        rule %r/\s+/, Text
        # module Foo (functions)
        rule %r/([A-Z][\w.]*)(\s+)(\()/ do
          groups Name::Namespace, Text, Punctuation
          push :funclist
        end

        rule %r/\bwhere\b/, Keyword::Reserved, :pop!

        rule %r/[A-Z][a-zA-Z0-9_.]*/, Name::Namespace, :pop!
      end

      state :funclist do
        mixin :basic
        rule %r/[A-Z]\w*/, Keyword::Type
        rule %r/(_[\w\']+|[a-z][\w\']*)/, Name::Function
        rule %r/,/, Punctuation
        rule %r/[:!#\$\%&*+.\\\/<=>?@^\|~-]+/, Operator
        rule %r/\(/, Punctuation, :funclist
        rule %r/\)/, Punctuation, :pop!
      end

      state :character do
        rule %r/\\/ do
          token Str::Escape
          goto :character_end
          push :escape
        end

        rule %r/./ do
          token Str::Char
          goto :character_end
        end
      end

      state :character_end do
        rule %r/'/, Str::Char, :pop!
        rule %r/./, Error, :pop!
      end

      state :quasiquotation do
        rule %r/\|\]/, Operator, :pop!
        rule %r/[^\|]+/m, Text
        rule %r/\|/, Text
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\/, Str::Escape, :escape
        rule %r/[^\\"]+/, Str
      end

      state :escape do
        rule %r/[abfnrtv"'&\\]/, Str::Escape, :pop!
        rule %r/\^[\]\[A-Z@\^_]/, Str::Escape, :pop!
        rule %r/#{ascii.join('|')}/, Str::Escape, :pop!
        rule %r/o[0-7]+/i, Str::Escape, :pop!
        rule %r/x[\da-f]+/i, Str::Escape, :pop!
        rule %r/\d+/, Str::Escape, :pop!
        rule %r/\s+\\/, Str::Escape, :pop!
      end
    end
  end
end
