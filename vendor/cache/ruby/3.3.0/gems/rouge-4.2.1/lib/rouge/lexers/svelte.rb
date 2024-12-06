# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'html.rb'

    class Svelte < HTML
      desc 'Svelte single-file components (https://svelte.dev/)'
      tag 'svelte'
      filenames '*.svelte'
      mimetypes 'text/x-svelte', 'application/x-svelte'

      def initialize(*)
        super
        # todo add support for typescript script blocks
        @js = Javascript.new(options)
      end

      # Shorthand syntax for passing attributes - ex, `{src}` instead of `src={src}`
      prepend :tag do
        rule %r/(\{)\s*([a-zA-Z0-9_]+)\s*(})/m do
          groups Str::Interpol, Name::Variable, Str::Interpol
          pop!
        end
      end

      prepend :attr do
        # Duplicate template_start mixin here with a pop!
        # Because otherwise we'll never exit the attr state
        rule %r/\{/ do
          token Str::Interpol
          pop!
          push :template
        end
      end

      # handle templates within attribute single/double quotes
      prepend :dq do
        mixin :template_start
      end

      prepend :sq do
        mixin :template_start
      end

      prepend :root do
        # detect curly braces within HTML text (outside of tags/attributes)
        rule %r/([^<&{]*)(\{)(\s*)/ do
          groups Text, Str::Interpol, Text
          push :template
        end
      end

      state :template_start do
        # open template
        rule %r/\s*\{\s*/, Str::Interpol, :template
      end

      state :template do
        # template end
        rule %r/}/, Str::Interpol, :pop!

        # Allow JS lexer to handle matched curly braces within template
        rule(/(?<=^|[^\\])\{.*?(?<=^|[^\\])\}/) do
          delegate @js
        end

        # keywords
        rule %r/@(debug|html)\b/, Keyword
        rule %r/(#await)(.*)(then|catch)(\s+)(\w+)/ do |m|
          token Keyword, m[1]
          delegate @js, m[2]
          token Keyword, m[3]
          token Text, m[4]
          delegate @js, m[5]
        end
        rule %r/([#\/])(await|each|if|key)\b/, Keyword
        rule %r/(:else)(\s+)(if)?\b/ do
          groups Keyword, Text, Keyword
        end
        rule %r/:?(catch|then)\b/, Keyword

        # allow JS parser to handle anything that's not a curly brace
        rule %r/[^{}]+/ do
          delegate @js
        end
      end
    end
  end
end
