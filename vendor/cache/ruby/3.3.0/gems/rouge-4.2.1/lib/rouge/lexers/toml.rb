# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class TOML < RegexLexer
      title "TOML"
      desc 'the TOML configuration format (https://github.com/toml-lang/toml)'
      tag 'toml'

      filenames '*.toml', 'Pipfile', 'poetry.lock'
      mimetypes 'text/x-toml'

      # bare keys and quoted keys
      identifier = %r/(?:\S+|"[^"]+"|'[^']+')/

      state :basic do
        rule %r/\s+/, Text
        rule %r/#.*?$/, Comment
        rule %r/(true|false)/, Keyword::Constant

        rule %r/(#{identifier})(\s*)(=)(\s*)(\{)/ do
          groups Name::Property, Text, Operator, Text, Punctuation
          push :inline
        end
      end

      state :root do
        mixin :basic

        rule %r/(?<!=)\s*\[.*?\]+/, Name::Namespace

        rule %r/(#{identifier})(\s*)(=)/ do
          groups Name::Property, Text, Punctuation
          push :value
        end
      end

      state :value do
        rule %r/\n/, Text, :pop!
        mixin :content
      end

      state :content do
        mixin :basic

        rule %r/(#{identifier})(\s*)(=)/ do
          groups Name::Property, Text, Punctuation
        end

        rule %r/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/, Literal::Date

        rule %r/[+-]?\d+(?:_\d+)*\.\d+(?:_\d+)*(?:[eE][+-]?\d+(?:_\d+)*)?/, Num::Float
        rule %r/[+-]?\d+(?:_\d+)*[eE][+-]?\d+(?:_\d+)*/, Num::Float
        rule %r/[+-]?(?:nan|inf)/, Num::Float

        rule %r/0x\h+(?:_\h+)*/, Num::Hex
        rule %r/0o[0-7]+(?:_[0-7]+)*/, Num::Oct
        rule %r/0b[01]+(?:_[01]+)*/, Num::Bin
        rule %r/[+-]?\d+(?:_\d+)*/, Num::Integer

        rule %r/"""/, Str, :mdq
        rule %r/"/, Str, :dq
        rule %r/'''/, Str, :msq
        rule %r/'/, Str, :sq
        mixin :esc_str
        rule %r/\,/, Punctuation
        rule %r/\[/, Punctuation, :array
      end

      state :dq do
        rule %r/"/, Str, :pop!
        rule %r/\n/, Error, :pop!
        mixin :esc_str
        rule %r/[^\\"\n]+/, Str
      end

      state :mdq do
        rule %r/"""/, Str, :pop!
        mixin :esc_str
        rule %r/[^\\"]+/, Str
        rule %r/"+/, Str
      end

      state :sq do
        rule %r/'/, Str, :pop!
        rule %r/\n/, Error, :pop!
        rule %r/[^'\n]+/, Str
      end

      state :msq do
        rule %r/'''/, Str, :pop!
        rule %r/[^']+/, Str
        rule %r/'+/, Str
      end

      state :esc_str do
        rule %r/\\[0t\tn\n "\\r]/, Str::Escape
      end

      state :array do
        mixin :content
        rule %r/\]/, Punctuation, :pop!
      end

      state :inline do
        mixin :content

        rule %r/\}/, Punctuation, :pop!
      end
    end
  end
end
