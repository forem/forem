# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Clean < RegexLexer
      title "Clean"
      desc "The Clean programming language (clean.cs.ru.nl)"

      tag 'clean'
      filenames '*.dcl', '*.icl'

      def self.keywords
        @keywords ||= Set.new %w(
          if otherwise
          let in
          with where
          case of
          infix infixl infixr
          class instance
          generic derive
          special
          implementation definition system module
          from import qualified as
          dynamic
          code inline foreign export ccall stdcall
        )
      end

      # These are literal patterns common to the ABC intermediate language and
      # Clean. Clean has more extensive literal patterns (see :basic below).
      state :common_literals do
        rule %r/'(?:[^'\\]|\\(?:x[0-9a-fA-F]+|\d+|.))'/, Str::Char

        rule %r/[+~-]?\d+\.\d+(?:E[+-]?\d+)?\b/, Num::Float
        rule %r/[+~-]?\d+E[+-]?\d+\b/, Num::Float
        rule %r/[+~-]?\d+/, Num::Integer

        rule %r/"/, Str::Double, :string
      end

      state :basic do
        rule %r/\s+/m, Text::Whitespace

        rule %r/\/\/\*.*/, Comment::Doc
        rule %r/\/\/.*/, Comment::Single
        rule %r/\/\*\*/, Comment::Doc, :comment_doc
        rule %r/\/\*/, Comment::Multiline, :comment

        rule %r/[+~-]?0[0-7]+/, Num::Oct
        rule %r/[+~-]?0x[0-9a-fA-F]+/, Num::Hex
        mixin :common_literals
        rule %r/(\[)(\s*)(')(?=.*?'\])/ do
          groups Punctuation, Text::Whitespace, Str::Single, Punctuation
          push :charlist
        end
      end

      # nested commenting
      state :comment_doc do
        rule %r/\*\//, Comment::Doc, :pop!
        rule %r/\/\/.*/, Comment::Doc # Singleline comments in multiline comments are skipped
        rule %r/\/\*/, Comment::Doc, :comment
        rule %r/[^*\/]+/, Comment::Doc
        rule %r/[*\/]/, Comment::Doc
      end

      # This is the same as the above, but with Multiline instead of Doc
      state :comment do
        rule %r/\*\//, Comment::Multiline, :pop!
        rule %r/\/\/.*/, Comment::Multiline # Singleline comments in multiline comments are skipped
        rule %r/\/\*/, Comment::Multiline, :comment
        rule %r/[^*\/]+/, Comment::Multiline
        rule %r/[*\/]/, Comment::Multiline
      end

      state :root do
        mixin :basic

        rule %r/code(\s+inline)?\s*{/, Comment::Preproc, :abc

        rule %r/_*[a-z][\w`]*/ do |m|
          if self.class.keywords.include?(m[0])
            token Keyword
          else
            token Name
          end
        end

        rule %r/_*[A-Z][\w`]*/ do |m|
          if m[0]=='True' || m[0]=='False'
            token Keyword::Constant
          else
            token Keyword::Type
          end
        end

        rule %r/[^\w\s`]/, Punctuation
        rule %r/_\b/, Punctuation
      end

      state :escapes do
        rule %r/\\x[0-9a-fA-F]{1,2}/i, Str::Escape
        rule %r/\\d\d{0,3}/i, Str::Escape
        rule %r/\\0[0-7]{0,3}/, Str::Escape
        rule %r/\\[0-7]{1,3}/, Str::Escape
        rule %r/\\[nrfbtv\\"']/, Str::Escape
      end

      state :string do
        rule %r/"/, Str::Double, :pop!
        mixin :escapes
        rule %r/[^\\"]+/, Str::Double
      end

      state :charlist do
        rule %r/(')(\])/ do
          groups Str::Single, Punctuation
          pop!
        end
        mixin :escapes
        rule %r/[^\\']/, Str::Single
      end

      state :abc_basic do
        rule %r/\s+/, Text::Whitespace
        rule %r/\|.*/, Comment::Single
        mixin :common_literals
      end

      # The ABC intermediate language can be included, similar to C's inline
      # assembly. For some information about ABC, see:
      # https://en.wikipedia.org/wiki/Clean_(programming_language)#The_ABC-Machine
      state :abc do
        mixin :abc_basic

        rule %r/}/, Comment::Preproc, :pop!
        rule %r/\.\w*/, Keyword, :abc_rest_of_line
        rule %r/[\w]+/, Name::Builtin, :abc_rest_of_line
      end

      state :abc_rest_of_line do
        rule %r/\n/, Text::Whitespace, :pop!
        rule %r/}/ do
          token Comment::Preproc
          pop!
          pop!
        end

        mixin :abc_basic

        rule %r/\S+/, Name
      end
    end
  end
end
