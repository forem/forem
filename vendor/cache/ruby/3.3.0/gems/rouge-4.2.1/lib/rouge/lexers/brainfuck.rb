# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Brainfuck < RegexLexer
      tag 'brainfuck'
      filenames '*.b', '*.bf'
      mimetypes 'text/x-brainfuck'

      title "Brainfuck"
      desc "The Brainfuck programming language"

      start { push :bol }

      state :bol do
        rule %r/\s+/m, Text
        rule %r/\[/, Comment::Multiline, :comment_multi
        rule(//) { pop! }
      end

      state :root do
        rule %r/\]/, Error
        rule %r/\[/, Punctuation, :loop

        mixin :comment_single
        mixin :commands
      end

      state :comment_multi do
        rule %r/\[/, Comment::Multiline, :comment_multi
        rule %r/\]/, Comment::Multiline, :pop!
        rule %r/[^\[\]]+?/m, Comment::Multiline
      end

      state :comment_single do
        rule %r/[^><+\-.,\[\]]+/, Comment::Single
      end

      state :loop do
        rule %r/\[/, Punctuation, :loop
        rule %r/\]/, Punctuation, :pop!
        mixin :comment_single
        mixin :commands
      end

      state :commands do
        rule %r/[><]+/, Name::Builtin
        rule %r/[+\-.,]+/, Name::Function
      end
    end
  end
end
