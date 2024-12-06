# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class MsgTrans < RegexLexer
      title "MessageTrans"
      desc "RISC OS message translator messages file"
      tag 'msgtrans'
      filenames 'Messages', 'Message[0-9]', 'Message[1-9][0-9]', 'Message[1-9][0-9][0-9]'

      state :root do
        rule %r/^#[^\n]*/, Comment
        rule %r/[^\t\n\r ,):?\/]+/, Name::Variable
        rule %r/[\n\/?]/, Operator
        rule %r/:/, Operator, :value
      end

      state :value do
        rule %r/\n/, Text, :pop!
        rule %r/%[0-3%]/, Operator
        rule %r/[^\n%]/, Literal::String
      end
    end
  end
end
