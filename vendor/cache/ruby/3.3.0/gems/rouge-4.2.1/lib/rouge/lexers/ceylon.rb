# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Ceylon < RegexLexer
      tag 'ceylon'
      filenames '*.ceylon'
      mimetypes 'text/x-ceylon'

      title "Ceylon"
      desc 'Say more, more clearly.'

      state :whitespace do
        rule %r([^\S\n]+), Text
        rule %r(//.*?\n), Comment::Single
        rule %r(/\*), Comment::Multiline
      end

      state :root do
        mixin :whitespace

        rule %r((shared|abstract|formal|default|actual|variable|deprecated|small|
          late|literal|doc|by|see|throws|optional|license|tagged|final|native|
          annotation|sealed)\b), Name::Decorator

        rule %r((break|case|catch|continue|else|finally|for|in|
          if|return|switch|this|throw|try|while|is|exists|dynamic|
          nonempty|then|outer|assert|let)\b), Keyword

        rule %r((abstracts|extends|satisfies|super|given|of|out|assign)\b), Keyword::Declaration

        rule %r((function|value|void|new)\b), Keyword::Type

        rule %r((assembly|module|package)(\s+)) do
          groups Keyword::Namespace, Text
          push :import
        end

        rule %r((true|false|null)\b), Keyword::Constant

        rule %r((class|interface|object|alias)(\s+)) do
          groups Keyword::Declaration, Text
          push :class
        end

        rule %r((import)(\s+)) do
          groups Keyword::Namespace, Text
          push :import
        end

        rule %r("(\\\\|\\"|[^"])*"), Literal::String
        rule %r('\\.'|'[^\\]'|'\\\{#[0-9a-fA-F]{4}\}'), Literal::String::Char
        rule %r("[^`]*``[^`]*``[^`]*"), Literal::String::Interpol
        rule %r((\.)([a-z_]\w*)) do
          groups Operator, Name::Attribute
        end
        rule %r([a-zA-Z_]\w*:), Name::Label
        rule %r((\\I[a-z]|[A-Z])\w*), Name::Decorator
        rule %r([a-zA-Z_]\w*), Name
        rule %r([~^*!%&\[\](){}<>|+=:;,./?`-]), Operator
        rule %r(\d{1,3}(_\d{3})+\.\d{1,3}(_\d{3})+[kMGTPmunpf]?), Literal::Number::Float
        rule %r(\d{1,3}(_\d{3})+\.[0-9]+([eE][+-]?[0-9]+)?[kMGTPmunpf]?),
          Literal::Number::Float
        rule %r([0-9][0-9]*\.\d{1,3}(_\d{3})+[kMGTPmunpf]?), Literal::Number::Float
        rule %r([0-9][0-9]*\.[0-9]+([eE][+-]?[0-9]+)?[kMGTPmunpf]?),
          Literal::Number::Float
        rule %r(#([0-9a-fA-F]{4})(_[0-9a-fA-F]{4})+), Literal::Number::Hex
        rule %r(#[0-9a-fA-F]+), Literal::Number::Hex
        rule %r(\$([01]{4})(_[01]{4})+), Literal::Number::Bin
        rule %r(\$[01]+), Literal::Number::Bin
        rule %r(\d{1,3}(_\d{3})+[kMGTP]?), Literal::Number::Integer
        rule %r([0-9]+[kMGTP]?), Literal::Number::Integer
        rule %r(\n), Text

      end

      state :class do
        mixin :whitespace
        rule %r([A-Za-z_]\w*), Name::Class, :pop!
      end

      state :import do
        rule %r([a-z][\w.]*), Name::Namespace, :pop!
        rule %r("(\\\\|\\"|[^"])*"), Literal::String, :pop!
      end

      state :comment do
        rule %r([^*/]), Comment.Multiline
        rule %r(/\*), Comment::Multiline, :push!
        rule %r(\*/), Comment::Multiline, :pop!
        rule %r([*/]), Comment::Multiline
      end
    end
  end
end
