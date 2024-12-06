# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Conf < RegexLexer
      tag 'conf'
      aliases 'config', 'configuration'

      title "Config File"
      desc 'A generic lexer for configuration files'
      filenames '*.conf', '*.config'

      # short and sweet
      state :root do
        rule %r/#.*?\n/, Comment
        rule %r/".*?"/, Str::Double
        rule %r/'.*?'/, Str::Single
        rule %r/[a-z]\w*/i, Name
        rule %r/\d+/, Num
        rule %r/[^\w#"']+/, Text
      end
    end
  end
end
