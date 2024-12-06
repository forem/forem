# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'console.rb'

    class IRBLexer < ConsoleLexer
      tag 'irb'
      aliases 'pry'

      desc 'Shell sessions in IRB or Pry'

      # unlike the superclass, we do not accept any options
      @option_docs = {}

      def output_lexer
        @output_lexer ||= IRBOutputLexer.new(@options)
      end

      def lang_lexer
        @lang_lexer ||= Ruby.new(@options)
      end

      def prompt_regex
        %r(
          ^.*?
          (
            (irb|pry).*?[>"*] |
            [>"*]>
          )
        )x
      end

      def allow_comments?
        true
      end
    end

    load_lexer 'ruby.rb'
    class IRBOutputLexer < Ruby
      tag 'irb_output'

      start do
        push :stdout
      end

      state :has_irb_output do
        rule %r(=>), Punctuation, :pop!
        rule %r/.+?(\n|$)/, Generic::Output
      end

      state :irb_error do
        rule %r/.+?(\n|$)/, Generic::Error
        mixin :has_irb_output
      end

      state :stdout do
        rule %r/\w+?(Error|Exception):.+?(\n|$)/, Generic::Error, :irb_error
        mixin :has_irb_output
      end

      prepend :root do
        rule %r/#</, Keyword::Type, :irb_object
      end

      state :irb_object do
        rule %r/>/, Keyword::Type, :pop!
        mixin :root
      end
    end
  end
end
