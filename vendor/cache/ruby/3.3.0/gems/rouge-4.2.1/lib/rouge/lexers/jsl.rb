# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class JSL < RegexLexer
      title "JSL"
      desc "The JMP Scripting Language (JSL) (jmp.com)"

      tag 'jsl'
      filenames '*.jsl'

      state :root do
        rule %r/\s+/m, Text::Whitespace

        rule %r(//.*?$), Comment::Single
        rule %r'/[*].*?', Comment::Multiline, :comment # multiline block comment

        # messages
        rule %r/<</, Operator, :message

        # covers built-in and custom functions
        rule %r/(::|:)?([a-z_][\w\s'%.\\]*)(\()/i do |m|
          groups Punctuation, Keyword, Punctuation
        end

        rule %r/\d{2}(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\d{2}(\d{2})?(:\d{2}:\d{2}(:\d{2}(\.\d*)?)?)?/i, Literal::Date

        rule %r/-?(?:[0-9]+(?:[.][0-9]+)?|[.][0-9]*)(?:e[+-]?[0-9]+)?i?/i, Num

        rule %r/(::|:)?([a-z_][\w\s'%.\\]*|"(?:\\!"|[^"])*?"n)/i do |m|
          groups Punctuation, Name::Variable
        end

        rule %r/(")(\\\[)(.*?)(\]\\)(")/m do
          groups Str::Double, Str::Escape, Str::Double, Str::Escape, Str::Double  # escaped string
        end
        rule %r/"/, Str::Double, :dq

        rule %r/[-+*\/!%&<>\|=:`^]/, Operator
        rule %r/[\[\](){},;]/, Punctuation
      end

      state :message do
        rule %r/\s+/m, Text::Whitespace
        rule %r/[a-z_][\w\s'%.\\]*/i, Name::Function
        rule %r/[(),;]/, Punctuation, :pop!
        rule %r/[&|!=<>]/, Operator, :pop!
      end

      state :dq do
        rule %r/\\![btrnNf0\\"]/, Str::Escape
        rule %r/\\/, Str::Double
        rule %r/"/, Str::Double, :pop!
        rule %r/[^\\"]+/m, Str::Double
      end

      state :comment do
        rule %r'/[*]', Comment::Multiline, :comment
        rule %r'[*]/', Comment::Multiline, :pop!
        rule %r'[^/*]+', Comment::Multiline
        rule %r'[/*]', Comment::Multiline
      end
    end
  end
end
