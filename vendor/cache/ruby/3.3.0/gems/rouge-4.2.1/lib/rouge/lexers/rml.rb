# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class RML < RegexLexer
      title "RML"
      desc "A system agnostic domain-specific language for runtime monitoring and verification (https://rmlatdibris.github.io/)"
      tag 'rml'
      filenames '*.rml'

      def self.keywords
        @keywords ||= Set.new %w(
          matches not with empty
          all if else true false
        )
      end

      def self.arithmetic_keywords
        @arithmetic_keywords ||= Set.new %w(
          abs sin cos tan min max
        )
      end

      id_char = /[a-zA-Z0-9_]/
      uppercase_id = /[A-Z]#{id_char}*/
      lowercase_id = /[a-z]#{id_char}*/

      ellipsis = /(\.){3}/
      int = /[0-9]+/
      float = /#{int}\.#{int}/
      string = /'(\\'|[ a-zA-Z0-9_.])*'/

      whitespace = /[ \t\r\n]+/
      comment = /\/\/[^\r\n]*/

      state :common_rules do
        rule %r/#{whitespace}/, Text
        rule %r/#{comment}/, Comment::Single
        rule %r/#{string}/, Literal::String
        rule %r/#{float}/, Num::Float
        rule %r/#{int}/, Num::Integer
      end

      state :root do
        mixin :common_rules
        rule %r/(#{lowercase_id})(\()/ do
          groups Name::Function, Operator
          push :event_type_params
        end
        rule %r/#{lowercase_id}/ do |m|
          if m[0] == 'with'
            token Keyword
            push :data_expression_with
          elsif self.class.keywords.include? m[0]
            token Keyword
          else
            token Name::Function
          end
        end
        rule %r/\(|\{|\[/, Operator, :event_type_params
        rule %r/[_\|]/, Operator
        rule %r/#{uppercase_id}/, Name::Class, :equation_block_expression
        rule %r/;/, Operator
      end

      state :event_type_params do
        mixin :common_rules
        rule %r/\(|\{|\[/, Operator, :push
        rule %r/\)|\}|\]/, Operator, :pop!
        rule %r/#{lowercase_id}(?=:)/, Name::Entity
        rule %r/(#{lowercase_id})/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          else
            token Literal::String::Regex
          end
        end
        rule %r/#{ellipsis}/, Literal::String::Symbol
        rule %r/[_\|;,:]/, Operator
      end

      state :equation_block_expression do
        mixin :common_rules
        rule %r/[<,>]/, Operator
        rule %r/#{lowercase_id}/, Literal::String::Regex
        rule %r/=/ do
          token Operator
          goto :exp
        end
        rule %r/;/, Operator, :pop!
      end

      state :exp do
        mixin :common_rules
        rule %r/(if)(\()/ do
          groups Keyword, Operator
          push :data_expression
        end
        rule %r/let|var/, Keyword, :equation_block_expression
        rule %r/(#{lowercase_id})(\()/ do
          groups Name::Function, Operator
          push :event_type_params
        end
        rule %r/(#{lowercase_id})/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          else
            token Name::Function
          end
        end
        rule %r/#{uppercase_id}(?=<)/, Name::Class, :data_expression
        rule %r/#{uppercase_id}/, Name::Class
        rule %r/[=(){}*+\/\\\|!>?]/, Operator
        rule %r/;/, Operator, :pop!
      end

      state :data_expression do
        mixin :common_rules
        rule %r/#{lowercase_id}/ do |m|
          if (self.class.arithmetic_keywords | self.class.keywords).include? m[0]
            token Keyword
          else
            token Literal::String::Regex
          end
        end
        rule %r/\(/, Operator, :push
        rule %r/\)/, Operator, :pop!
        rule %r/(>)(?=[^A-Z;]+[A-Z;>])/, Operator, :pop!
        rule %r/[*^?!%&\[\]<>\|+=:,.\/\\_-]/, Operator
        rule %r/;/, Operator, :pop!
      end

      state :data_expression_with do
        mixin :common_rules
        rule %r/>/, Operator
        mixin :data_expression

      end
    end
  end
end
