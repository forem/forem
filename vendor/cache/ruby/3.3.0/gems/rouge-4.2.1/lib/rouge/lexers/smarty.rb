# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Smarty < TemplateLexer
      title "Smarty"
      desc 'Smarty Template Engine'
      tag 'smarty'
      aliases 'smarty'
      filenames '*.tpl', '*.smarty'
      mimetypes 'application/x-smarty', 'text/x-smarty'

      def self.builtins
        @builtins ||= %w(
          append assign block call capture config_load debug extends
          for foreach foreachelse break continue function if elseif
          else include include_php insert ldelim rdelim literal nocache
          php section sectionelse setfilter strip while
          counter cycle eval fetch html_checkboxes html_image html_options
          html_radios html_select_date html_select_time html_table
          mailto math textformat
          capitalize cat count_characters count_paragraphs
          count_sentences count_words date_format default escape
          from_charset indent lower nl2br regex_replace replace spacify
          string_format strip strip_tags to_charset truncate unescape
          upper wordwrap
        )
      end


      state :root do
        rule(/\{\s+/) { delegate parent }

        # block comments
        rule %r/\{\*.*?\*\}/m, Comment

        rule %r/\{\/?(?![\s*])/ do
          token Keyword
          push :smarty
        end


        rule(/.+?(?={[\/a-zA-Z0-9$#*"'])/m) { delegate parent }
        rule(/.+/m) { delegate parent }
      end

      state :comment do
        rule(/{\*/) { token Comment; push }
        rule(/\*}/) { token Comment; pop! }
        rule(/[^{}]+/m) { token Comment }
      end

      state :smarty do
        # allow nested tags
        rule %r/\{\/?(?![\s*])/ do
          token Keyword
          push :smarty
        end

        rule %r/}/, Keyword, :pop!
        rule %r/\s+/m, Text
        rule %r([~!%^&*()+=|\[\]:;,.<>/@?-]), Operator
        rule %r/#[a-zA-Z_]\w*#/, Name::Variable
        rule %r/\$[a-zA-Z_]\w*(\.\w+)*/, Name::Variable
        rule %r/(true|false|null)\b/, Keyword::Constant
        rule %r/[0-9](\.[0-9]*)?(eE[+-][0-9])?[flFLdD]?|0[xX][0-9a-fA-F]+[Ll]?/, Num
        rule %r/"(\\.|.)*?"/, Str::Double
        rule %r/'(\\.|.)*?'/, Str::Single

        rule %r/([a-zA-Z_]\w*)/ do |m|
          if self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Attribute
          end
        end
      end
    end
  end
end
