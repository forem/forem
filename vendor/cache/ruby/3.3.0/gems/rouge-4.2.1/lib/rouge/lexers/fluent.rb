# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Fluent < RegexLexer
      title 'Fluent'
      desc 'Fluent localization files'
      tag 'fluent'
      aliases 'ftl'
      filenames '*.ftl'

      state :root do
        rule %r{( *)(\=)( *)} do
          groups Text::Whitespace, Punctuation, Text::Whitespace
          push :template
        end

        rule %r{(?:\s*\n)+}m, Text::Whitespace
        rule %r{\#{1,3}(?: .*)?$}, Comment::Single
        rule %r{[a-zA-Z][a-zA-Z0-9_-]*}, Name::Constant
        rule %r{\-[a-zA-Z][a-zA-Z0-9_-]*}, Name::Entity
        rule %r{\s*\.[a-zA-Z][a-zA-Z0-9_-]*}, Name::Attribute
        rule %r{\s+(?=[^\s\.])}, Text::Whitespace, :template
      end

      state :template do
        rule %r{\n}m, Text::Whitespace, :pop!
        rule %r{[^\{\n\}\*]+}, Text
        rule %r{\{}, Punctuation, :placeable
        rule %r{(?=\})}, Punctuation, :pop!
      end

      state :placeable do
        rule %r{\s+}m, Text::Whitespace
        rule %r{\{}, Punctuation, :placeable
        rule %r{\}}, Punctuation, :pop!
        rule %r{\$[a-zA-Z][a-zA-Z0-9_-]*}, Name::Variable
        rule %r{\-[a-zA-Z][a-zA-Z0-9_-]*}, Name::Entity
        rule %r{\.[a-zA-Z][a-zA-Z0-9_-]*}, Name::Attribute
        rule %r{[A-Z]+}, Name::Builtin
        rule %r{[a-zA-Z][a-zA-Z0-9_-]*}, Name::Constant
        rule %r{[\(\),\:]}, Punctuation
        rule %r{->}, Punctuation
        rule %r{\*}, Punctuation::Indicator
        rule %r{\-?\d+\.\d+?}, Literal::Number::Float
        rule %r{\-?\d+}, Literal::Number::Integer
        rule %r{"}, Str::Double, :string

        rule %r{(\[)(\-?\d+\.\d+)(\])} do
          groups Punctuation, Literal::Number::Float, Punctuation
          push :template
        end

        rule %r{(\[)(\-?\d+)(\])} do
          groups Punctuation, Literal::Number::Integer, Punctuation
          push :template
        end

        rule %r{(\[)([a-zA-Z][a-zA-Z0-9_-]+)(\])} do
          groups Punctuation, Str::Symbol, Punctuation
          push :template
        end
      end

      state :string do
        rule %r{\\u[0-9a-fA-F]{4}|\\U[0-9a-fA-F]{6}}, Str::Escape
        rule %r{\\.}, Str::Escape
        rule %r{[^\"\\]}, Str::Double
        rule %r{"}, Str::Double, :pop!
      end
    end
  end
end
