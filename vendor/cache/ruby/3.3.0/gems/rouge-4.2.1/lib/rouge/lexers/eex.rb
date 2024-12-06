# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class EEX < TemplateLexer
      title "EEX"
      desc "Embedded Elixir"

      tag 'eex'
      aliases 'leex', 'heex'

      filenames '*.eex', '*.leex', '*.heex'

      def initialize(opts={})
        @elixir_lexer = Elixir.new(opts)

        super(opts)
      end

      start do
        parent.reset!
        @elixir_lexer.reset!
      end

      open  = /<%%|<%=|<%#|<%/
      close = /%%>|%>/

      state :root do
        rule %r/<%#/, Comment, :comment

        rule open, Comment::Preproc, :elixir

        rule %r/.+?(?=#{open})|.+/mo do
          delegate parent
        end
      end

      state :comment do
        rule close, Comment, :pop!
        rule %r/.+?(?=#{close})|.+/mo, Comment
      end

      state :elixir do
        rule close, Comment::Preproc, :pop!

        rule %r/.+?(?=#{close})|.+/mo do
          delegate @elixir_lexer
        end
      end
    end
  end
end
