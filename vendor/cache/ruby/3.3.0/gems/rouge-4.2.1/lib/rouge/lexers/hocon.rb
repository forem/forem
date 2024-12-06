# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'json.rb'

    class HOCON < JSON
      title 'HOCON'
      desc "Human-Optimized Config Object Notation (https://github.com/lightbend/config)"
      tag 'hocon'
      filenames '*.hocon'

      state :comments do
        # Comments
        rule %r(//.*?$), Comment::Single
        rule %r(#.*?$), Comment::Single
      end

      prepend :root do
        mixin :comments
      end

      prepend :object do
        # Keywords
        rule %r/\b(?:include|url|file|classpath)\b/, Keyword
      end

      state :name do
        rule %r/("(?:\"|[^"\n])*?")(\s*)([:=]|(?={))/ do
          groups Name::Label, Text::Whitespace, Punctuation
        end

        rule %r/([-\w.]+)(\s*)([:=]|(?={))/ do
          groups Name::Label, Text::Whitespace, Punctuation
        end
      end

      state :value do
        mixin :comments

        rule %r/\n/, Text::Whitespace
        rule %r/\s+/, Text::Whitespace

        mixin :constants

        # Interpolation
        rule %r/[$][{][?]?/, Literal::String::Interpol, :interpolation

        # Strings
        rule %r/"""/, Literal::String::Double, :multiline_string
        rule %r/"/, Str::Double, :string

        rule %r/\[/, Punctuation, :array
        rule %r/{/, Punctuation, :object

        # Symbols (only those not handled by JSON)
        rule %r/[()=]/, Punctuation

        # Values
        rule %r/[^$"{}\[\]:=,\+#`^?!@*&]+?/, Literal
      end

      state :interpolation do
        rule %r/[\w\-\.]+?/, Name::Variable
        rule %r/}/, Literal::String::Interpol, :pop!
      end

      prepend :string do
        rule %r/[$][{][?]?/, Literal::String::Interpol, :interpolation
        rule %r/[^\\"\${]+/, Literal::String::Double
      end

      state :multiline_string do
        rule %r/"[^"]{1,2}/, Literal::String::Double
        mixin :string
        rule %r/"""/, Literal::String::Double, :pop!
      end

      prepend :constants do
        # Numbers (handle the case where we have multiple periods, ie. IP addresses)
        rule %r/\d+\.(\d+\.?){3,}/, Literal
      end
    end
  end
end
