# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Turtle < RegexLexer
      title "Turtle/TriG"
      desc "Terse RDF Triple Language, TriG"
      tag 'turtle'
      filenames '*.ttl', '*.trig'
      mimetypes 'text/turtle', 'application/trig'

      state :root do
        rule %r/@base\b/, Keyword::Declaration
        rule %r/@prefix\b/, Keyword::Declaration
        rule %r/true\b/, Keyword::Constant
        rule %r/false\b/, Keyword::Constant

        rule %r/""".*?"""/m, Literal::String
        rule %r/"([^"\\]|\\.)*"/, Literal::String
        rule %r/'''.*?'''/m, Literal::String
        rule %r/'([^'\\]|\\.)*'/, Literal::String

        rule %r/#.*$/, Comment::Single

        rule %r/@[^\s,.;]+/, Name::Attribute

        rule %r/[+-]?[0-9]+\.[0-9]*E[+-]?[0-9]+/, Literal::Number::Float
        rule %r/[+-]?\.[0-9]+E[+-]?[0-9]+/, Literal::Number::Float
        rule %r/[+-]?[0-9]+E[+-]?[0-9]+/, Literal::Number::Float

        rule %r/[+-]?[0-9]*\.[0-9]+?/, Literal::Number::Float

        rule %r/[+-]?[0-9]+/, Literal::Number::Integer

        rule %r/\./, Punctuation
        rule %r/,/, Punctuation
        rule %r/;/, Punctuation
        rule %r/\(/, Punctuation
        rule %r/\)/, Punctuation
        rule %r/\{/, Punctuation
        rule %r/\}/, Punctuation
        rule %r/\[/, Punctuation
        rule %r/\]/, Punctuation
        rule %r/\^\^/, Punctuation

        rule %r/<[^>]*>/, Name::Label

        rule %r/base\b/i, Keyword::Declaration
        rule %r/prefix\b/i, Keyword::Declaration
        rule %r/GRAPH\b/, Keyword
        rule %r/a\b/, Keyword

        rule %r/\s+/, Text::Whitespace

        rule %r/[^:;<>#\@"\(\).\[\]\{\} ]*:/, Name::Namespace
        rule %r/[^:;<>#\@"\(\).\[\]\{\} ]+/, Name
      end
    end
  end
end
