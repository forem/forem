# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Handlebars < TemplateLexer
      title "Handlebars"
      desc 'the Handlebars and Mustache templating languages'
      tag 'handlebars'
      aliases 'hbs', 'mustache'
      filenames '*.handlebars', '*.hbs', '*.mustache'
      mimetypes 'text/x-handlebars', 'text/x-mustache'

      id = %r([\w$-]+)

      state :root do
        # escaped slashes
        rule(/\\{+/) { delegate parent }

        # block comments
        rule %r/{{!--/, Comment, :comment
        rule %r/{{!.*?}}/, Comment

        rule %r/{{{?/ do
          token Keyword
          push :stache
          push :open_sym
        end

        rule(/(.+?)(?=\\|{{)/m) do
          delegate parent

          # if parent state is attr, then we have an html attribute without quotes
          # pop the parent state to return to the tag state
          if parent.state?('attr')
            parent.pop!
          end
        end

        # if we get here, there's no more mustache tags, so we eat
        # the rest of the doc
        rule(/.+/m) { delegate parent }
      end

      state :comment do
        rule(/{{/) { token Comment; push }
        rule(/}}/) { token Comment; pop! }
        rule(/[^{}]+/m) { token Comment }
        rule(/[{}]/) { token Comment }
      end

      state :stache do
        rule %r/}}}?/, Keyword, :pop!
        rule %r/\|/, Punctuation
        rule %r/~/, Keyword
        rule %r/\s+/m, Text
        rule %r/[=]/, Operator
        rule %r/[\[\]]/, Punctuation
        rule %r/[\(\)]/, Punctuation
        rule %r/[.](?=[}\s])/, Name::Variable
        rule %r/[.][.]/, Name::Variable
        rule %r([/.]), Punctuation
        rule %r/"(\\.|.)*?"/, Str::Double
        rule %r/'(\\.|.)*?'/, Str::Single
        rule %r/\d+(?=}\s)/, Num
        rule %r/(true|false)(?=[}\s])/, Keyword::Constant
        rule %r/else(?=[}\s])/, Keyword
        rule %r/this(?=[}\s])/, Name::Builtin::Pseudo
        rule %r/@#{id}/, Name::Attribute
        rule id, Name::Variable
      end

      state :open_sym do
        rule %r([#/]) do
          token Keyword
          goto :block_name
        end

        rule %r/[>^&~]/, Keyword

        rule(//) { pop! }
      end

      state :block_name do
        rule %r/if(?=[}\s])/, Keyword
        rule id, Name::Namespace, :pop!
        rule(//) { pop! }
      end
    end
  end
end
