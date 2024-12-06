# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Nginx < RegexLexer
      title "nginx"
      desc 'configuration files for the nginx web server (nginx.org)'
      tag 'nginx'
      mimetypes 'text/x-nginx-conf'
      filenames 'nginx.conf'

      id = /[^\s$;{}()#]+/

      state :root do
        rule %r/(include)(\s+)([^\s;]+)/ do
          groups Keyword, Text, Name
        end

        rule id, Keyword, :statement

        mixin :base
      end

      state :block do
        rule %r/}/, Punctuation, :pop!
        rule id, Keyword::Namespace, :statement
        mixin :base
      end

      state :statement do
        rule %r/{/ do
          token Punctuation; pop!; push :block
        end

        rule %r/;/, Punctuation, :pop!

        mixin :base
      end

      state :base do
        rule %r/\s+/, Text

        rule %r/#.*/, Comment::Single
        rule %r/(?:on|off)\b/, Name::Constant
        rule %r/[$][\w-]+/, Name::Variable

        # host/port
        rule %r/([a-z0-9.-]+)(:)([0-9]+)/i do
          groups Name::Function, Punctuation, Num::Integer
        end

        # mimetype
        rule %r([a-z-]+/[a-z-]+)i, Name::Class

        rule %r/\d+\.\d+/, Num::Float
        rule %r/[0-9]+[kmg]?\b/i, Num::Integer
        rule %r/(~)(\s*)([^\s{]+)/ do
          groups Punctuation, Text, Str::Regex
        end

        rule %r/[:=~]/, Punctuation

        # pathname
        rule %r(/#{id}?), Name

        rule %r/[^#\s;{}$\\]+/, Str # catchall

        rule %r/[$;]/, Text
      end
    end
  end
end
