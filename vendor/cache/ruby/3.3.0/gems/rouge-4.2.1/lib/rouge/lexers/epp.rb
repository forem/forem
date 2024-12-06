# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    class EPP < TemplateLexer
      title "EPP"
      desc "Embedded Puppet template files"

      tag 'epp'

      filenames '*.epp'

      def initialize(opts={})
        super(opts)
        @parent = lexer_option(:parent) { PlainText.new(opts) }
        @puppet_lexer = Puppet.new(opts)
      end

      start do
        parent.reset!
        @puppet_lexer.reset!
      end

      open  = /<%%|<%=|<%#|(<%-|<%)(\s*\|)?/
      close = /%%>|(\|\s*)?(-%>|%>)/

      state :root do
        rule %r/<%#/, Comment, :comment

        rule open, Comment::Preproc, :puppet

        rule %r/.+?(?=#{open})|.+/m do
          delegate parent
        end
      end

      state :comment do
        rule close, Comment, :pop!
        rule %r/.+?(?=#{close})|.+/m, Comment
      end

      state :puppet do
        rule close, Comment::Preproc, :pop!

        rule %r/.+?(?=#{close})|.+/m do
          delegate @puppet_lexer
        end
      end
    end
  end
end
