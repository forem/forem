# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'xpath.rb'
    class XQuery < XPath
      title 'XQuery'
      desc 'XQuery 3.1: An XML Query Language'
      tag 'xquery'
      filenames '*.xquery', '*.xq', '*.xqm'
      mimetypes 'application/xquery'

      def self.keywords
        @keywords ||= Regexp.union super, Regexp.union(%w(
          xquery encoding version declare module
          namespace copy-namespaces boundary-space construction
          default collation base-uri preserve strip
          ordering ordered unordered order empty greatest least
          preserve no-preserve inherit no-inherit
          decimal-format decimal-separator grouping-separator
          infinity minus-sign NaN percent per-mille
          zero-digit digit pattern-separator exponent-separator
          import schema at element option
          function external context item
          typeswitch switch case
          try catch
          validate lax strict type
          document element attribute text comment processing-instruction
          for let where order group by return
          allowing tumbling stable sliding window
          start end only when previous next count collation
          ascending descending
        ))
      end

      # Mixin states:

      state :tags do
        rule %r/<#{XPath.qName}/, Name::Tag, :start_tag
        rule %r/<!--/, Comment, :xml_comment
        rule %r/<\?.*?\?>/, Comment::Preproc
        rule %r/<!\[CDATA\[.*?\]\]>/, Comment::Preproc
        rule %r/&\S*?;/, Name::Entity
      end

      # Lexical states:

      prepend :root do
        mixin :tags

        rule %r/\{/, Punctuation
        rule %r/\}`?/ do
          token Punctuation
          if stack.length > 1
            pop!
          end
        end

        rule %r/(namespace)(\s+)(#{XPath.ncName})/ do
          groups Keyword, Text::Whitespace, Name::Namespace
        end

        rule %r/(#{XQuery.keywords})\b/, Keyword
        rule %r/;/, Punctuation
        rule %r/%/, Keyword::Declaration, :annotation

        rule %r/(\(#)(\s*)(#{XPath.eqName})/ do
          groups Comment::Preproc, Text::Whitespace, Name::Tag
          push :pragma
        end

        rule %r/``\[/, Str, :str_constructor
      end

      state :annotation do
        mixin :commentsAndWhitespace
        rule XPath.eqName, Keyword::Declaration, :pop!
      end

      state :pragma do
        mixin :commentsAndWhitespace
        rule %r/#\)/, Comment::Preproc, :pop!
        rule %r/./, Comment::Preproc
      end

      # https://www.w3.org/TR/xquery-31/#id-string-constructors
      state :str_constructor do
        rule %r/`\{/, Punctuation, :root
        rule %r/\]``/, Str, :pop!
        rule %r/[^`\]]+/m, Str
        rule %r/[`\]]/, Str
      end

      state :xml_comment do
        rule %r/[^-]+/m, Comment
        rule %r/-->/, Comment, :pop!
        rule %r/-/, Comment
      end

      state :start_tag do
        rule %r/\s+/m, Text::Whitespace
        rule %r/([\w.:-]+\s*=)(")/m do
          groups Name::Attribute, Str
          push :quot_attr
        end
        rule %r/([\w.:-]+\s*=)(')/m do
          groups Name::Attribute, Str
          push :apos_attr
        end
        rule %r/>/, Name::Tag, :tag_content
        rule %r(/>), Name::Tag, :pop!
      end

      state :quot_attr do
        rule %r/"/, Str, :pop!
        rule %r/\{\{/, Str
        rule %r/\{/, Punctuation, :root
        rule %r/[^"{>]+/m, Str
      end

      state :apos_attr do
        rule %r/'/, Str, :pop!
        rule %r/\{\{/, Str
        rule %r/\{/, Punctuation, :root
        rule %r/[^'{>]+/m, Str
      end

      state :tag_content do
        rule %r/\s+/m, Text::Whitespace
        mixin :tags

        rule %r/(\{\{|\}\})/, Text
        rule %r/\{/, Punctuation, :root

        rule %r/[^{}<&]/, Text

        rule %r(</#{XPath.qName}(\s*)>) do
          token Name::Tag
          pop! 2 # pop self and tag_start
        end
      end
    end
  end
end
