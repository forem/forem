# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Dot < RegexLexer
      title "DOT"
      desc "graph description language"

      tag 'dot'
      aliases 'graphviz'
      filenames '*.dot'
      mimetypes 'text/vnd.graphviz'

      start do
        @html = HTML.new(options)
      end

      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(#.*), Comment::Single
        rule %r(//.*?$), Comment::Single
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :html do
        rule %r/[^<>]+/ do
          delegate @html
        end
        rule %r/<.+?>/m do
          delegate @html
        end
        rule %r/>/, Punctuation, :pop!
      end

      state :ID do
        rule %r/([a-zA-Z][a-zA-Z_0-9]*)(\s*)(=)/ do |m|
          token Name, m[1]
          token Text, m[2]
          token Punctuation, m[3]
        end
        rule %r/[a-zA-Z][a-zA-Z_0-9]*/, Name::Variable
        rule %r/([0-9]+)?\.[0-9]+/, Num::Float
        rule %r/[0-9]+/, Num::Integer
        rule %r/"(\\"|[^"])*"/, Str::Double
        rule %r/</ do
          token Punctuation
          @html.reset!
          push :html
        end
      end

      state :a_list do
        mixin :comments_and_whitespace
        mixin :ID
        rule %r/[=;,]/, Punctuation
        rule %r/\]/, Operator, :pop!
      end

      state :root do
        mixin :comments_and_whitespace
        rule %r/\b(strict|graph|digraph|subgraph|node|edge)\b/i, Keyword
        rule %r/[{};:=]/, Punctuation
        rule %r/-[->]/, Operator
        rule %r/\[/, Operator, :a_list
        mixin :ID
      end
    end
  end
end
