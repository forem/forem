# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Elm < RegexLexer
      title "Elm"
      desc "The Elm programming language (http://elm-lang.org/)"

      tag 'elm'
      filenames '*.elm'
      mimetypes 'text/x-elm'

      # Keywords are logically grouped by lines
      keywords = %w(
        module exposing port
        import as
        type alias
        if then else
        case of
        let in
      )

      state :root do
        # Whitespaces
        rule %r/\s+/m, Text
        # Single line comments
        rule %r/--.*/, Comment::Single
        # Multiline comments
        rule %r/{-/, Comment::Multiline, :multiline_comment

        # Keywords
        rule %r/\b(#{keywords.join('|')})\b/, Keyword

        # Variable or a function
        rule %r/[a-z]\w*/, Name
        # Underscore is a name for a variable, when it won't be used later
        rule %r/_/, Name
        # Type
        rule %r/[A-Z]\w*/, Keyword::Type

        # Two symbol operators: -> :: // .. && || ++ |> <| << >> == /= <= >=
        rule %r/(->|::|\/\/|\.\.|&&|\|\||\+\+|\|>|<\||>>|<<|==|\/=|<=|>=)/, Operator
        # One symbol operators: + - / * % = < > ^ | !
        rule %r/[+-\/*%=<>^\|!]/, Operator
        # Lambda operator
        rule %r/\\/, Operator
        # Not standard Elm operators, but these symbols can be used for custom inflix operators. We need to highlight them as operators as well.
        rule %r/[@\#$&~?]/, Operator

        # Single, double quotes, and triple double quotes
        rule %r/"""/, Str, :multiline_string
        rule %r/'(\\.|.)'/, Str::Char
        rule %r/"/, Str, :double_quote

        # Numbers
        rule %r/0x[\da-f]+/i, Num::Hex
        rule %r/\d+e[+-]?\d+/i, Num::Float
        rule %r/\d+\.\d+(e[+-]?\d+)?/i, Num::Float
        rule %r/\d+/, Num::Integer

        # Punctuation: [ ] ( ) , ; ` { } :
        rule %r/[\[\](),;`{}:]/, Punctuation
      end

      # Multiline and nested commenting
      state :multiline_comment do
        rule %r/-}/, Comment::Multiline, :pop!
        rule %r/{-/, Comment::Multiline, :multiline_comment
        rule %r/[^-{}]+/, Comment::Multiline
        rule %r/[-{}]/, Comment::Multiline
      end

      # Double quotes
      state :double_quote do
        rule %r/[^\\"]+/, Str::Double
        rule %r/\\"/, Str::Escape
        rule %r/"/, Str::Double, :pop!
      end

      # Multiple line string with triple double quotes, e.g. """ multi """
      state :multiline_string do
        rule %r/\\"/, Str::Escape
        rule %r/"""/, Str, :pop!
        rule %r/[^"]+/, Str
        rule %r/"/, Str
      end
    end
  end
end
