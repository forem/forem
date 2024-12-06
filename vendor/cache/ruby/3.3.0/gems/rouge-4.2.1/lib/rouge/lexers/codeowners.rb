# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Codeowners < RegexLexer
      title 'CODEOWNERS'
      desc 'Code Owners syntax (https://docs.gitlab.com/ee/user/project/codeowners/reference.html)'
      tag 'codeowners'
      filenames 'CODEOWNERS'

      state :root do
        rule %r/[ \t\r\n]+/, Text::Whitespace
        rule %r/^\s*#.*$/, Comment::Single

        rule %r(
          (\^?\[(?!\d+\])[^\]]+\])
          (\[\d+\])?
        )x do
          groups Name::Namespace, Literal::Number
        end

        rule %r/\S*@\S+/, Name::Function

        rule %r/[\p{Word}\.\/\-\*]+/, Name
        rule %r/.*\\[\#\s]/, Name
      end
    end
  end
end
