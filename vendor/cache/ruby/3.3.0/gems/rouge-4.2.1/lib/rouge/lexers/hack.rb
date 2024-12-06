# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'php.rb'

    class Hack < PHP
      title 'Hack'
      desc 'The Hack programming language (hacklang.org)'
      tag 'hack'
      aliases 'hack', 'hh'
      filenames '*.php', '*.hh'

      def self.detect?(text)
        return true if /<\?hh/ =~ text
        return true if text.shebang?('hhvm')
        return true if /async function [a-zA-Z]/ =~ text
        return true if /\): Awaitable</ =~ text

        return false
      end

      def self.keywords
        @hh_keywords ||= super.merge Set.new %w(
          type newtype enum
          as super
          async await Awaitable
          vec dict keyset
          void int string bool float double
          arraykey num Stringish
        )
      end

      prepend :root do
        rule %r/<\?hh(\s*\/\/\s*(strict|decl|partial))?$/, Comment::Preproc, :php
      end

      prepend :php do
        rule %r((/\*\s*)(HH_(?:IGNORE_ERROR|FIXME)\[\d+\])([^*]*)(\*/)) do
          groups Comment::Preproc, Comment::Preproc, Comment::Multiline, Comment::Preproc
        end

        rule %r(// UNSAFE(?:_EXPR|_BLOCK)?), Comment::Preproc
        rule %r(/\*\s*UNSAFE_EXPR\s*\*/), Comment::Preproc
      end
    end
  end
end
