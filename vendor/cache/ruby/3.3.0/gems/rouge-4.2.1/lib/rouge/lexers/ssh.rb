# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class SSH < RegexLexer
      tag 'ssh'

      title "SSH Config File"
      desc 'A lexer for SSH configuration files'
      filenames 'ssh_config'

      state :root do
        rule %r/[a-z0-9]+/i, Keyword, :statement
        mixin :base
      end

      state :statement do
        rule %r/\n/, Text, :pop!
        rule %r/(?:yes|no|confirm|ask|always|auto|none|force)\b/, Name::Constant

        rule %r/\d+/, Num
        rule %r/[^#\s;{}$\\]+/, Text
        mixin :base
      end

      state :base do
        rule %r/\s+/, Text
        rule %r/#.*/, Comment::Single
      end
    end
  end
end
