# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # shared states with Reasonml and ReScript
    class OCamlCommon < RegexLexer
      def self.keywords
        @keywords ||= Set.new %w(
          as assert begin class constraint do done downto else end
          exception external false for fun function functor if in
          include inherit initializer lazy let module mutable new
          nonrec object of open rec sig struct then to true try type
          val virtual when while with
        )
      end

      def self.word_operators
        @word_operators ||= Set.new %w(and asr land lor lsl lxor mod or)
      end

      def self.primitives
        @primitives ||= Set.new %w(unit int float bool string char list array)
      end

      @@operator = %r([;,_!$%&*+./:<=>?@^|~#-]+)
      @@id = /[a-z_][\w']*/i
      @@upper_id = /[A-Z][\w']*/

      state :string do
        rule %r/[^\\"]+/, Str::Double
        mixin :escape_sequence
        rule %r/\\\n/, Str::Double
        rule %r/"/, Str::Double, :pop!
      end

      state :escape_sequence do
        rule %r/\\[\\"'ntbr]/, Str::Escape
        rule %r/\\\d{3}/, Str::Escape
        rule %r/\\x\h{2}/, Str::Escape
      end

      state :dotted do
        rule %r/\s+/m, Text
        rule %r/[.]/, Punctuation
        rule %r/#{@@upper_id}(?=\s*[.])/, Name::Namespace
        rule @@upper_id, Name::Class, :pop!
        rule @@id, Name, :pop!
        rule %r/[({\[]/, Punctuation, :pop!
      end
    end
  end
end
