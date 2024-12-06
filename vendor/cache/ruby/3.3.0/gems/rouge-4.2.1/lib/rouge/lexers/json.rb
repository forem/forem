# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class JSON < RegexLexer
      title 'JSON'
      desc "JavaScript Object Notation (json.org)"
      tag 'json'
      filenames '*.json', 'Pipfile.lock'
      mimetypes 'application/json', 'application/vnd.api+json',
                'application/hal+json', 'application/problem+json',
                'application/schema+json'

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
      end

      state :root do
        mixin :whitespace
        rule %r/{/, Punctuation, :object
        rule %r/\[/, Punctuation, :array

        mixin :name
        mixin :value

        # These characters may be invalid but syntax correctness is a non-goal
        rule %r/[\]}]/, Punctuation
      end

      state :object do
        mixin :whitespace
        mixin :name
        mixin :value
        rule %r/}/, Punctuation, :pop!
        rule %r/,/, Punctuation
      end

      state :name do
        rule %r/("(?:\\.|[^"\\\n])*?")(\s*)(:)/ do
          groups Name::Label, Text::Whitespace, Punctuation
        end
      end

      state :value do
        mixin :whitespace
        mixin :constants
        rule %r/"/, Str::Double, :string
        rule %r/\[/, Punctuation, :array
        rule %r/{/, Punctuation, :object
      end

      state :string do
        rule %r/[^\\"]+/, Str::Double
        rule %r/\\./, Str::Escape
        rule %r/"/, Str::Double, :pop!
      end

      state :array do
        mixin :value
        rule %r/\]/, Punctuation, :pop!
        rule %r/,/, Punctuation
      end

      state :constants do
        rule %r/(?:true|false|null)/, Keyword::Constant
        rule %r/-?(?:0|[1-9]\d*)\.\d+(?:e[+-]?\d+)?/i, Num::Float
        rule %r/-?(?:0|[1-9]\d*)(?:e[+-]?\d+)?/i, Num::Integer
      end
    end
  end
end
