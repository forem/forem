# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'sass/common.rb'

    class Sass < SassCommon
      include Indentation

      title "Sass"
      desc 'The Sass stylesheet language language (sass-lang.com)'

      tag 'sass'
      filenames '*.sass'
      mimetypes 'text/x-sass'

      id = /[\w-]+/

      state :root do
        rule %r/[ \t]*\n/, Text
        rule(/[ \t]*/) { |m| token Text; indentation(m[0]) }
      end

      state :content do
        # block comments
        rule %r(//.*?$) do
          token Comment::Single
          pop!; starts_block :single_comment
        end

        rule %r(/[*].*?\n) do
          token Comment::Multiline
          pop!; starts_block :multi_comment
        end

        rule %r/@import\b/, Keyword, :import

        mixin :content_common

        rule %r(=#{id}), Name::Function, :value
        rule %r([+]#{id}), Name::Decorator, :value

        rule %r/:/, Name::Attribute, :old_style_attr

        rule(/(?=[^\[\n]+?:([^a-z]|$))/) { push :attribute }

        rule(//) { push :selector }
      end

      state :single_comment do
        rule %r/.*?$/, Comment::Single, :pop!
      end

      state :multi_comment do
        rule %r/.*?\n/, Comment::Multiline, :pop!
      end

      state :import do
        rule %r/[ \t]+/, Text
        rule %r/\S+/, Str
        rule %r/\n/, Text, :pop!
      end

      state :old_style_attr do
        mixin :attr_common
        rule(//) { pop!; push :value }
      end

      state :end_section do
        rule(/\n/) { token Text; reset_stack }
      end
    end
  end
end
