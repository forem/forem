# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Docker < RegexLexer
      title "Docker"
      desc "Dockerfile syntax"
      tag 'docker'
      aliases 'dockerfile', 'Dockerfile'
      filenames 'Dockerfile', '*.Dockerfile', '*.docker'
      mimetypes 'text/x-dockerfile-config'

      KEYWORDS = %w(
        FROM MAINTAINER CMD LABEL EXPOSE ENV ADD COPY ENTRYPOINT VOLUME USER WORKDIR ARG STOPSIGNAL HEALTHCHECK SHELL
      ).join('|')

      start { @shell = Shell.new(@options) }

      state :root do
        rule %r/\s+/, Text

        rule %r/^(FROM)(\s+)(.*)(\s+)(AS)(\s+)(.*)/io do
          groups Keyword, Text::Whitespace, Str, Text::Whitespace, Keyword, Text::Whitespace, Str
        end

        rule %r/^(ONBUILD)(\s+)(#{KEYWORDS})(.*)/io do
          groups Keyword, Text::Whitespace, Keyword, Str
        end

        rule %r/^(#{KEYWORDS})\b(.*)/io do
          groups Keyword, Str
        end

        rule %r/#.*?$/, Comment

        rule %r/^(ONBUILD\s+)?RUN(\s+)/i do
          token Keyword
          push :run
          @shell.reset!
        end

        rule %r/\w+/, Text
        rule %r/[^\w]+/, Text
        rule %r/./, Text
      end

      state :run do
        rule %r/\n/, Text, :pop!
        rule %r/\\./m, Str::Escape
        rule(/(\\.|[^\n\\])+/) { delegate @shell }
      end
    end
  end
end
