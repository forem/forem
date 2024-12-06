# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class GraphQL < RegexLexer
      desc 'GraphQL'
      tag 'graphql'
      filenames '*.graphql', '*.gql'
      mimetypes 'application/graphql'

      name = /[_A-Za-z][_0-9A-Za-z]*/

      state :root do
        rule %r/\b(?:query|mutation|subscription)\b/, Keyword, :query_definition
        rule %r/\{/ do
          token Punctuation
          push :query_definition
          push :selection_set
        end

        rule %r/\bfragment\b/, Keyword, :fragment_definition

        rule %r/\bscalar\b/, Keyword, :value

        rule %r/\b(?:type|interface|enum)\b/, Keyword, :type_definition

        rule %r/\b(?:input|schema)\b/, Keyword, :type_definition

        rule %r/\bunion\b/, Keyword, :union_definition

        rule %r/\bextend\b/, Keyword

        mixin :basic

        # Markdown descriptions
        rule %r/(""")(\n)(.*?)(\n)(""")/m do |m|
          token Str::Double, m[1]
          token Text::Whitespace, m[2]
          delegate Markdown, m[3]
          token Text::Whitespace, m[4]
          token Str::Double, m[5]
        end
      end

      state :basic do
        rule %r/\s+/m, Text::Whitespace
        rule %r/#.*$/, Comment

        rule %r/[!,]/, Punctuation
      end

      state :has_directives do
        rule %r/(@#{name})(\s*)(\()/ do
          groups Keyword, Text::Whitespace, Punctuation
          push :arguments
        end
        rule %r/@#{name}\b/, Keyword
      end

      state :fragment_definition do
        rule %r/\bon\b/, Keyword

        mixin :query_definition
      end

      state :query_definition do
        mixin :has_directives

        rule %r/\b#{name}\b/, Name
        rule %r/\(/, Punctuation, :variable_definitions
        rule %r/\{/, Punctuation, :selection_set

        mixin :basic
      end

      state :type_definition do
        rule %r/\bimplements\b/, Keyword
        rule %r/\b#{name}\b/, Name
        rule %r/\(/, Punctuation, :variable_definitions
        rule %r/\{/, Punctuation, :type_definition_set

        mixin :basic
      end

      state :union_definition do
        rule %r/\b#{name}\b/, Name
        rule %r/\=/, Punctuation, :union_definition_variant

        mixin :basic
      end

      state :union_definition_variant do
        rule %r/\b#{name}\b/ do
          token Name
          pop!
          push :union_definition_pipe
        end

        mixin :basic
      end

      state :union_definition_pipe do
        rule %r/\|/ do
          token Punctuation
          pop!
          push :union_definition_variant
        end

        rule %r/(?!\||\s+|#[^\n]*)/ do
          pop! 2
        end

        mixin :basic
      end

      state :type_definition_set do
        rule %r/\}/ do
          token Punctuation
          pop! 2
        end

        rule %r/\b(#{name})(\s*)(\()/ do
          groups Name, Text::Whitespace, Punctuation
          push :variable_definitions
        end
        rule %r/\b#{name}\b/, Name

        rule %r/:/, Punctuation, :type_names

        mixin :basic
      end

      state :arguments do
        rule %r/\)/ do
          token Punctuation
          pop!
        end

        rule %r/\b#{name}\b/, Name
        rule %r/:/, Punctuation, :value

        mixin :basic
      end

      state :variable_definitions do
        rule %r/\)/ do
          token Punctuation
          pop!
        end

        rule %r/\$#{name}\b/, Name::Variable
        rule %r/\b#{name}\b/, Name
        rule %r/:/, Punctuation, :type_names
        rule %r/\=/, Punctuation, :value

        mixin :basic
      end

      state :type_names do
        rule %r/\b(?:Int|Float|String|Boolean|ID)\b/, Name::Builtin, :pop!
        rule %r/\b#{name}\b/, Name, :pop!

        rule %r/\[/, Punctuation, :type_name_list

        mixin :basic
      end

      state :type_name_list do
        rule %r/\b(?:Int|Float|String|Boolean|ID)\b/, Name::Builtin
        rule %r/\b#{name}\b/, Name

        rule %r/\]/ do
          token Punctuation
          pop! 2
        end

        mixin :basic
      end

      state :selection_set do
        mixin :has_directives

        rule %r/\}/ do
          token Punctuation
          pop!
          pop! if state?(:query_definition) || state?(:fragment_definition)
        end

        rule %r/\b(#{name})(\s*)(\()/ do
          groups Name, Text::Whitespace, Punctuation
          push :arguments
        end

        rule %r/\b(#{name})(\s*)(:)/ do
          groups Name, Text::Whitespace, Punctuation
        end

        rule %r/\b#{name}\b/, Name

        rule %r/(\.\.\.)(\s+)(on)\b/ do
          groups Punctuation, Text::Whitespace, Keyword
        end
        rule %r/\.\.\./, Punctuation

        rule %r/\{/, Punctuation, :selection_set

        mixin :basic
      end

      state :list do
        rule %r/\]/ do
          token Punctuation
          pop!
          pop! if state?(:value)
        end

        mixin :value
      end

      state :object do
        rule %r/\}/ do
          token Punctuation
          pop!
          pop! if state?(:value)
        end

        rule %r/\b(#{name})(\s*)(:)/ do
          groups Name, Text::Whitespace, Punctuation
          push :value
        end

        mixin :basic
      end

      state :value do
        pop_unless_list = ->(t) {
          ->(m) {
            token t
            pop! unless state?(:list)
          }
        }

        # Multiline strings
        rule %r/""".*?"""/m, Str::Double

        rule %r/\$#{name}\b/, &pop_unless_list[Name::Variable]
        rule %r/\b(?:true|false|null)\b/, &pop_unless_list[Keyword::Constant]
        rule %r/[+-]?[0-9]+\.[0-9]+(?:[eE][+-]?[0-9]+)?/, &pop_unless_list[Num::Float]
        rule %r/[+-]?[1-9][0-9]*(?:[eE][+-]?[0-9]+)?/, &pop_unless_list[Num::Integer]
        rule %r/"(\\[\\"]|[^"])*"/, &pop_unless_list[Str::Double]
        rule %r/\b#{name}\b/, &pop_unless_list[Name]

        rule %r/\{/, Punctuation, :object
        rule %r/\[/, Punctuation, :list

        mixin :basic
      end
    end
  end
end
