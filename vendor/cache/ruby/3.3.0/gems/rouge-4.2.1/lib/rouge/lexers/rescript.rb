# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'ocaml/common.rb'

    class ReScript < OCamlCommon
      title "ReScript"
      desc "The ReScript programming language (rescript-lang.org)"
      tag 'rescript'
      filenames '*.res', '*.resi'
      mimetypes 'text/x-rescript'

      def self.keywords
        @keywords ||= Set.new(%w(
          open let rec and as exception assert lazy if else
          for in to downto while switch when external type private
          mutable constraint include module of with try import export
        ))
      end

      def self.types
        @types ||= Set.new(%w(
          bool int float char string
          unit list array option ref exn format
        ))
      end

      def self.word_operators
        @word_operators ||= Set.new(%w(mod land lor lxor lsl lsr asr or))
      end

      state :root do
        rule %r/\s+/m, Text
        rule %r([,.:?~\\]), Text

        # Boolean Literal
        rule %r/\btrue|false\b/, Keyword::Constant

        # Module chain
        rule %r/#{@@upper_id}(?=\s*[.])/, Name::Namespace, :dotted

        # Decorator
        rule %r/@#{@@id}(\.#{@@id})*/, Name::Decorator

        # Poly variant
        rule %r/\##{@@id}/, Name::Class

        # Variant or Module
        rule @@upper_id, Name::Class

        # Comments
        rule %r(//.*), Comment::Single
        rule %r(/\*), Comment::Multiline, :comment

        # Keywords and identifiers
        rule @@id do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.word_operators.include? match
            token Operator::Word
          elsif self.class.types.include? match
            token Keyword::Type
          else
            token Name
          end
        end

        # Braces
        rule %r/[(){}\[\];]+/, Punctuation

        # Operators
        rule %r([;_!$%&*+/<=>@^|-]+), Operator

        # Numbers
        rule %r/-?\d[\d_]*(.[\d_]*)?(e[+-]?\d[\d_]*)/i, Num::Float
        rule %r/0x\h[\h_]*/i, Num::Hex
        rule %r/0o[0-7][0-7_]*/i, Num::Oct
        rule %r/0b[01][01_]*/i, Num::Bin
        rule %r/\d[\d_]*/, Num::Integer

        # String and Char
        rule %r/'(?:(\\[\\"'ntbr ])|(\\[0-9]{3})|(\\x\h{2}))'/, Str::Char
        rule %r/'[^'\/]'/, Str::Char
        rule %r/'/, Keyword
        rule %r/"/, Str::Double, :string

        # Interpolated string
        rule %r/`/ do
          token Str::Double
          push :interpolated_string
        end
      end

      state :comment do
        rule %r([^/\*]+), Comment::Multiline
        rule %r(/\*), Comment::Multiline, :comment
        rule %r(\*/), Comment::Multiline, :pop!
        rule %r([*/]), Comment::Multiline
      end

      state :interpolated_string do
        rule %r/[$]{/, Punctuation, :interpolated_expression
        rule %r/`/, Str::Double, :pop!
        rule %r/\\[$`]/, Str::Escape
        rule %r/[^$`\\]+/, Str::Double
        rule %r/[\\$]/, Str::Double
      end

      state :interpolated_expression do
        rule %r/}/, Punctuation, :pop!
        mixin :root
      end

    end
  end
end
