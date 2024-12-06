# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Wollok < RegexLexer
      title 'Wollok'
      desc 'Wollok lang'
      tag 'wollok'
      filenames '*.wlk', '*.wtest', '*.wpgm'

      keywords = %w(new super return if else var const override constructor)

      entity_name = /[a-zA-Z][a-zA-Z0-9]*/
      variable_naming = /_?#{entity_name}/

      state :whitespaces_and_comments do
        rule %r/\s+/m, Text::Whitespace
        rule %r(//.*$), Comment::Single
        rule %r(/\*(.|\s)*?\*/)m, Comment::Multiline
      end

      state :root do
        mixin :whitespaces_and_comments
        rule %r/(import)(.+$)/ do
          groups Keyword::Reserved, Text
        end
        rule %r/(class|object|mixin)/, Keyword::Reserved, :foo
        rule %r/test|program/, Keyword::Reserved #, :chunk_naming
        rule %r/(package)(\s+)(#{entity_name})/ do
          groups Keyword::Reserved, Text::Whitespace, Name::Class
        end
        rule %r/{|}/, Text
        mixin :keywords
        mixin :symbols
        mixin :objects
      end

      state :foo do
        mixin :whitespaces_and_comments
        rule %r/inherits|mixed|with|and/, Keyword::Reserved
        rule %r/#{entity_name}(?=\s*{)/ do |m|
          token Name::Class
          entities << m[0]
          pop!
        end
        rule %r/#{entity_name}/ do |m|
          token Name::Class
          entities << m[0]
        end
      end

      state :keywords do
        def any(expressions)
          /#{expressions.map { |keyword| "#{keyword}\\b" }.join('|')}/
        end

        rule %r/self\b/, Name::Builtin::Pseudo
        rule any(keywords), Keyword::Reserved
        rule %r/(method)(\s+)(#{variable_naming})/ do
          groups Keyword::Reserved, Text::Whitespace, Text
        end
      end

      state :objects do
        rule variable_naming do |m|
          variable = m[0]
          if entities.include?(variable) || ('A'..'Z').cover?(variable[0])
            token Name::Class
          else
            token Keyword::Variable
          end
        end
        rule %r/\.#{entity_name}/, Text
        mixin :literals
      end

      state :literals do
        mixin :whitespaces_and_comments
        rule %r/[0-9]+\.?[0-9]*/, Literal::Number
        rule %r/"[^"]*"/m, Literal::String
        rule %r/\[|\#{/, Punctuation, :lists
      end

      state :lists do
        rule %r/,/, Punctuation
        rule %r/]|}/, Punctuation, :pop!
        mixin :objects
      end

      state :symbols do
        rule %r/\+\+|--|\+=|-=|\*\*|!/, Operator
        rule %r/\+|-|\*|\/|%/, Operator
        rule %r/<=|=>|===|==|<|>/, Operator
        rule %r/and\b|or\b|not\b/, Operator
        rule %r/\(|\)|=/, Text
        rule %r/,/, Punctuation
      end

      private

      def entities
        @entities ||= []
      end
    end
  end
end
