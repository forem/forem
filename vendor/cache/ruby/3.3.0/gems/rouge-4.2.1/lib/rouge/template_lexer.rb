# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  # @abstract
  # A TemplateLexer is one that accepts a :parent option, to specify
  # which language is being templated.  The lexer class can specify its
  # own default for the parent lexer, which is otherwise defaulted to
  # HTML.
  class TemplateLexer < RegexLexer
    # the parent lexer - the one being templated.
    def parent
      return @parent if instance_variable_defined? :@parent
      @parent = lexer_option(:parent) || Lexers::HTML.new(@options)
    end

    option :parent, "the parent language (default: html)"

    start { parent.reset! }
  end
end
