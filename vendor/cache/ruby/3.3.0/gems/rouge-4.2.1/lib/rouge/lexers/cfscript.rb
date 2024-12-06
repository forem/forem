# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers

    class Cfscript < RegexLexer
      title "CFScript"
      desc 'CFScript, the CFML scripting language'
      tag 'cfscript'
      aliases 'cfc'
      filenames '*.cfc'

      def self.keywords
        @keywords ||= %w(
          if else var xml default break switch do try catch throw in continue for return while required
        )
      end

      def self.declarations
        @declarations ||= %w(
          component property function remote public package private
        )
      end

      def self.types
        @types ||= %w(
          any array binary boolean component date guid numeric query string struct uuid void xml
        )
      end

      constants = %w(application session client cookie super this variables arguments cgi)


      operators = %w(\+\+ -- && \|\| <= >= < > == != mod eq lt gt lte gte not is and or xor eqv imp equal contains \? )
      dotted_id = /[$a-zA-Z_][a-zA-Z0-9_.]*/

      state :root do
        mixin :comments_and_whitespace
        rule %r/(?:#{operators.join('|')}|does not contain|greater than(?: or equal to)?|less than(?: or equal to)?)\b/i, Operator, :expr_start
        rule %r([-<>+*%&|\^/!=]=?), Operator, :expr_start

        rule %r/[(\[,]/, Punctuation, :expr_start
        rule %r/;/, Punctuation, :statement
        rule %r/[)\].]/, Punctuation

        rule %r/[?]/ do
          token Punctuation
          push :ternary
          push :expr_start
        end

        rule %r/[{}]/, Punctuation, :statement

        rule %r/(?:#{constants.join('|')})\b/, Name::Constant
        rule %r/(?:true|false|null)\b/, Keyword::Constant
        rule %r/import\b/, Keyword::Namespace, :import
        rule %r/(#{dotted_id})(\s*)(:)(\s*)/ do
          groups Name, Text, Punctuation, Text
          push :expr_start
        end

        rule %r/([A-Za-z_$][\w.]*)(\s*)(\()/ do |m|
          if self.class.keywords.include? m[1]
            token Keyword, m[1]
            token Text, m[2]
            token Punctuation, m[3]
          else
            token Name::Function, m[1]
            token Text, m[2]
            token Punctuation, m[3]
          end
        end

        rule dotted_id do |m|
          if self.class.declarations.include? m[0]
            token Keyword::Declaration
            push :expr_start
          elsif self.class.keywords.include? m[0]
            token Keyword
            push :expr_start
          elsif self.class.types.include? m[0]
            token Keyword::Type
            push :expr_start
          else
            token Name::Other
          end
        end

        rule %r/[0-9][0-9]*\.[0-9]+([eE][0-9]+)?[fd]?/, Num::Float
        rule %r/0x[0-9a-fA-F]+/, Num::Hex
        rule %r/[0-9]+/, Num::Integer
        rule %r/"(\\\\|\\"|[^"])*"/, Str::Double
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Single

      end

      # same as java, broken out
      state :comments_and_whitespace do
        rule %r/\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline
      end

      state :expr_start do
        mixin :comments_and_whitespace

        rule %r/[{]/, Punctuation, :object

        rule %r//, Text, :pop!
      end

      state :statement do

        rule %r/[{}]/, Punctuation

        mixin :expr_start
      end

      # object literals
      state :object do
        mixin :comments_and_whitespace
        rule %r/[}]/ do
          token Punctuation
          push :expr_start
        end

        rule %r/(#{dotted_id})(\s*)(:)/ do
          groups Name::Other, Text, Punctuation
          push :expr_start
        end

        rule %r/:/, Punctuation
        mixin :root
      end

      # ternary expressions, where <dotted_id>: is not a label!
      state :ternary do
        rule %r/:/ do
          token Punctuation
          goto :expr_start
        end

        mixin :root
      end

      state :import do
        rule %r/\s+/m, Text
        rule %r/[a-z0-9_.]+\*?/i, Name::Namespace, :pop!
      end

    end
  end
end
