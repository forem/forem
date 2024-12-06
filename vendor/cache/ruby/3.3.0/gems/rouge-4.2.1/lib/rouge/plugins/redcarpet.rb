# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# this file is not require'd from the root.  To use this plugin, run:
#
#    require 'rouge/plugins/redcarpet'

module Rouge
  module Plugins
    module Redcarpet
      def block_code(code, language)
        lexer =
          begin
            Lexer.find_fancy(language, code)
          rescue Guesser::Ambiguous => e
            e.alternatives.first
          end
        lexer ||= Lexers::PlainText

        # XXX HACK: Redcarpet strips hard tabs out of code blocks,
        # so we assume you're not using leading spaces that aren't tabs,
        # and just replace them here.
        if lexer.tag == 'make'
          code.gsub! %r/^    /, "\t"
        end

        formatter = rouge_formatter(lexer)
        formatter.format(lexer.lex(code))
      end

      # override this method for custom formatting behavior
      def rouge_formatter(lexer)
        Formatters::HTMLLegacy.new(:css_class => "highlight #{lexer.tag}")
      end
    end
  end
end
