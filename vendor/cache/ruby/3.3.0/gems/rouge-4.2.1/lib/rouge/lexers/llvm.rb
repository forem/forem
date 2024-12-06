# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class LLVM < RegexLexer
      title "LLVM"
      desc 'The LLVM Compiler Infrastructure (http://llvm.org/)'
      tag 'llvm'

      filenames '*.ll'
      mimetypes 'text/x-llvm'

      string = /"[^"]*?"/
      identifier = /([-a-zA-Z$._][-a-zA-Z$._0-9]*|#{string})/

      def self.keywords
        Kernel::load File.join(Lexers::BASE_DIR, "llvm/keywords.rb")
        keywords
      end

      def self.instructions
        Kernel::load File.join(Lexers::BASE_DIR, "llvm/keywords.rb")
        instructions
      end

      def self.types
        Kernel::load File.join(Lexers::BASE_DIR, "llvm/keywords.rb")
        types
      end

      state :basic do
        rule %r/;.*?$/, Comment::Single
        rule %r/\s+/, Text

        rule %r/#{identifier}\s*:/, Name::Label

        rule %r/@(#{identifier}|\d+)/, Name::Variable::Global
        rule %r/#\d+/, Name::Variable::Global
        rule %r/(%|!)#{identifier}/, Name::Variable
        rule %r/(%|!)\d+/, Name::Variable

        rule %r/c?#{string}/, Str

        rule %r/0[xX][a-fA-F0-9]+/, Num
        rule %r/-?\d+(?:[.]\d+)?(?:[eE][-+]?\d+(?:[.]\d+)?)?/, Num

        rule %r/[=<>{}\[\]()*.,!]|x/, Punctuation
      end

      state :root do
        mixin :basic

        rule %r/i[1-9]\d*/, Keyword::Type

        rule %r/\w+/ do |m|
          if self.class.types.include? m[0]
            token Keyword::Type
          elsif self.class.instructions.include? m[0]
            token Keyword
          elsif self.class.keywords.include? m[0]
            token Keyword
          else
            token Error
          end
        end
      end
    end
  end
end
