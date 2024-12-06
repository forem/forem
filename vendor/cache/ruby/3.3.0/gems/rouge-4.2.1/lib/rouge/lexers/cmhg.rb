# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CMHG < RegexLexer
      title "CMHG"
      desc "RISC OS C module header generator source file"
      tag 'cmhg'
      filenames '*.cmhg'

      def self.preproc_keyword
        @preproc_keyword ||= %w(
          define elif else endif error if ifdef ifndef include line pragma undef warning
        )
      end

      state :root do
        rule %r/;[^\n]*/, Comment
        rule %r/^([ \t]*)(#[ \t]*(?:(?:#{CMHG.preproc_keyword.join('|')})(?:[ \t].*)?)?)(?=\n)/ do
          groups Text, Comment::Preproc
        end
        rule %r/[-a-z]+:/, Keyword::Declaration
        rule %r/[a-z_]\w+/i, Name::Entity
        rule %r/"[^"]*"/, Literal::String
        rule %r/(?:&|0x)\h+/, Literal::Number::Hex
        rule %r/\d+/, Literal::Number
        rule %r/[,\/()]/, Punctuation
        rule %r/[ \t]+/, Text
        rule %r/\n+/, Text
      end
    end
  end
end
