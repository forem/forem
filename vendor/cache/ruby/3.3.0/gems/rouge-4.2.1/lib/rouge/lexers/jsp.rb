# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class JSP < TemplateLexer
      desc 'JSP'
      tag 'jsp'
      filenames '*.jsp'
      mimetypes 'text/x-jsp', 'application/x-jsp'

      def initialize(*)
        super
        @java = Java.new
      end

      directives = %w(page include taglib)
      actions = %w(scriptlet declaration expression)

      state :root do

        rule %r/<%--/, Comment, :jsp_comment

        rule %r/<%@\s*(#{directives.join('|')})\s*/, Name::Tag, :jsp_directive

        rule %r/<jsp:directive\.(#{directives.join('|')})/, Name::Tag, :jsp_directive2

        rule %r/<jsp:(#{actions.join('|')})>/, Name::Tag, :jsp_expression

        # start of tag, e.g. <c:if>
        rule %r/<[a-zA-Z]*:[a-zA-Z]*\s*/, Name::Tag, :jsp_tag

        # end of tag, e.g. </c:if>
        rule %r(</[a-zA-Z]*:[a-zA-Z]*>), Name::Tag

        rule %r/<%[!=]?/, Name::Tag, :jsp_expression2

        # fallback to HTML
        rule(/(.+?)(?=(<%|<\/?[a-zA-Z]*:))/m) { delegate parent }
        rule(/.+/m) { delegate parent }
      end

      state :jsp_comment do
        rule %r/(--%>)/, Comment, :pop!
        rule %r/./m, Comment
      end

      state :jsp_directive do
        rule %r/(%>)/, Name::Tag, :pop!
        mixin :attributes
        rule(/(.+?)(?=%>)/m) { delegate parent }
      end

      state :jsp_directive2 do
        rule %r!(/>)!, Name::Tag, :pop!
        mixin :attributes
        rule(/(.+?)(?=\/>)/m) { delegate parent }
      end

      state :jsp_expression do
        rule %r/<\/jsp:(#{actions.join('|')})>/, Name::Tag, :pop!
        mixin :attributes
        rule(/[^<\/]+/) { delegate @java }
      end

      state :jsp_expression2 do
        rule %r/%>/, Name::Tag, :pop!
        rule(/[^%>]+/) { delegate @java }
      end

      state :jsp_tag do
        rule %r/\/?>/, Name::Tag, :pop!
        mixin :attributes
        rule(/(.+?)(?=\/?>)/m) { delegate parent }
      end

      state :attributes do
        rule %r/\s*[a-zA-Z0-9_:-]+\s*=\s*/m, Name::Attribute, :attr
      end

      state :attr do
        rule %r/"/ do
          token Str
          goto :double_quotes
        end

        rule %r/'/ do
          token Str
          goto :single_quotes
        end

        rule %r/[^\s>]+/, Str, :pop!
      end

      state :double_quotes do
        rule %r/"/, Str, :pop!
        rule %r/\$\{/, Str::Interpol, :jsp_interp
        rule %r/[^"]+/, Str
      end

      state :single_quotes do
        rule %r/'/, Str, :pop!
        rule %r/\$\{/, Str::Interpol, :jsp_interp
        rule %r/[^']+/, Str
      end

      state :jsp_interp do
        rule %r/\}/, Str::Interpol, :pop!
        rule %r/'/, Literal, :jsp_interp_literal_start
        rule(/[^'\}]+/) { delegate @java }
      end

      state :jsp_interp_literal_start do
        rule %r/'/, Literal, :pop!
        rule %r/[^']+/, Literal
      end
    end
  end
end
