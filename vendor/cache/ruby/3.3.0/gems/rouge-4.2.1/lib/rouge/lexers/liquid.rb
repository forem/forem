# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Liquid < RegexLexer
      title "Liquid"
      desc 'Liquid is a templating engine for Ruby (liquidmarkup.org)'
      tag 'liquid'
      filenames '*.liquid'
      mimetypes 'text/html+liquid'

      state :root do
        rule %r/[^\{]+/, Text

        rule %r/(\{%-?)(\s*)/ do
          groups Comment::Preproc, Text::Whitespace
          push :logic
        end

        rule %r/(\{\{-?)(\s*)/ do
          groups Comment::Preproc, Text::Whitespace
          push :output
        end

        rule %r/\{/, Text
      end

      state :end_logic do
        rule(/(\s*)(-?%\})/) do
          groups Text::Whitespace, Comment::Preproc
          reset_stack
        end

        rule(/\n\s*/) do
          token Text::Whitespace
          if in_state? :liquid
            pop! until state? :liquid
          end
        end

        mixin :whitespace
      end

      state :end_output do
        rule(/(\s*)(-?\}\})/) do
          groups Text::Whitespace, Comment::Preproc
          reset_stack
        end
      end

      state :liquid do
        mixin :end_logic
        mixin :logic
      end

      state :logic do
        rule %r/(liquid)\b/, Name::Tag, :liquid

        # builtin logic blocks
        rule %r/(if|elsif|unless|case)\b/, Name::Tag, :condition
        rule %r/(when)\b/, Name::Tag, :value
        rule %r/(else|ifchanged|end\w+)\b/, Name::Tag, :end_logic
        rule %r/(break|continue)\b/, Keyword::Reserved, :end_logic

        # builtin iteration blocks
        rule %r/(for|tablerow)(\s+)(\S+)(\s+)(in)(\s+)/ do
          groups Name::Tag, Text::Whitespace, Name::Variable, Text::Whitespace,
                 Name::Tag, Text::Whitespace
          push :iteration_args
        end

        # other builtin blocks
        rule %r/(capture|(?:in|de)crement)(\s+)([a-zA-Z_](?:\w|-(?!%))*)/ do
          groups Name::Tag, Text::Whitespace, Name::Variable
          push :end_logic
        end

        rule %r/(comment)(\s*)(-?%\})/ do
          groups Name::Tag, Text::Whitespace, Comment::Preproc
          push :comment
        end

        rule %r/(raw)(\s*)(-?%\})/ do
          groups Name::Tag, Text::Whitespace, Comment::Preproc
          push :raw
        end

        # builtin tags
        rule %r/(assign|echo)\b/, Name::Tag, :assign

        rule %r/(include|render)(\s+)([\/\w-]+(?:\.[\w-]+)+\b)?/ do
          groups Name::Tag, Text::Whitespace, Text
          push :include
        end

        rule %r/(cycle)(\s+)(?:([\w-]+|'[^']*'|"[^"]*")(\s*)(:))?(\s*)/ do |m|
          token_class = case m[3]
                        when %r/'[^']*'/ then Str::Single
                        when %r/"[^"]*"/ then Str::Double
                        else
                          Name::Attribute
                        end
          groups Name::Tag, Text::Whitespace, token_class,
                 Text::Whitespace, Punctuation, Text::Whitespace
          push :tag_args
        end

        # custom tags or blocks
        rule %r/(\w+)\b/, Name::Tag, :block_args

        mixin :end_logic
      end

      state :output do
        rule %r/(\|)(\s*)/ do
          groups Punctuation, Text::Whitespace
          push :filters
          push :filter
        end

        mixin :end_output
        mixin :static
        mixin :variable
      end

      state :condition do
        rule %r/([=!]=|[<>]=?)/, Operator
        rule %r/(and|or|contains)\b/, Operator::Word

        mixin :value
      end

      state :value do
        mixin :end_logic
        mixin :static
        mixin :variable
      end

      state :iteration_args do
        rule %r/(reversed|continue)\b/, Name::Attribute
        rule %r/\(/, Punctuation, :range

        mixin :tag_args
      end

      state :block_args do
        rule %r/(\{\{-?)/, Comment::Preproc, :output_embed

        rule %r/(\|)(\s*)/ do
          groups Punctuation, Text::Whitespace
          push :filters
          push :filter
        end

        mixin :tag_args
      end

      state :tag_args do
        mixin :end_logic
        mixin :args
      end

      state :comment do
        rule %r/[^\{]+/, Comment

        rule %r/(\{%-?)(\s*)(endcomment)(\s*)(-?%\})/ do
          groups Comment::Preproc, Text::Whitespace, Name::Tag, Text::Whitespace, Comment::Preproc
          reset_stack
        end

        rule %r/\{/, Comment
      end

      state :raw do
        rule %r/[^\{]+/, Text

        rule %r/(\{%-?)(\s*)(endraw)(\s*)(-?%\})/ do
          groups Comment::Preproc, Text::Whitespace, Name::Tag, Text::Whitespace, Comment::Preproc
          reset_stack
        end

        rule %r/\{/, Text
      end

      state :assign do
        rule %r/=/, Operator
        rule %r/\(/, Punctuation, :range

        rule %r/(\|)(\s*)/ do
          groups Punctuation, Text::Whitespace
          push :filters
          push :filter
        end

        mixin :value
      end

      state :include do
        rule %r/(\{\{-?)/, Comment::Preproc, :output_embed
        rule %r/(with|for|as)\b/, Keyword::Reserved

        mixin :tag_args
      end

      state :output_embed do
        rule %r/(\|)(\s*)([a-zA-Z_](?:\w|-(?!}))*)/ do
          groups Punctuation, Text::Whitespace, Name::Function
        end

        rule %r/-?\}\}/, Comment::Preproc, :pop!

        mixin :args
      end

      state :range do
        rule %r/\.\./, Punctuation
        rule %r/\)/, Punctuation, :pop!

        mixin :whitespace
        mixin :number
        mixin :variable
      end

      state :filters do
        rule %r/(\|)(\s*)/ do
          groups Punctuation, Text::Whitespace
          push :filter
        end

        mixin :end_logic
        mixin :end_output
        mixin :args
      end

      state :filter do
        rule %r/[a-zA-Z_](?:\w|-(?![%}]))*/, Name::Function, :pop!
        
        mixin :whitespace
      end

      state :args do
        mixin :static

        rule %r/([a-zA-Z_][\w-]*)(\s*)(=|:)/ do
          groups Name::Attribute, Text::Whitespace, Operator
        end

        mixin :variable
      end

      state :static do
        rule %r/(false|true|nil)\b/, Keyword::Constant
        rule %r/'[^']*'/, Str::Single
        rule %r/"[^"]*"/, Str::Double
        rule %r/[,:]/, Punctuation

        mixin :whitespace
        mixin :number
      end

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
        rule %r/#.*?(?=$|-?[}%]})/, Comment
      end

      state :number do
        rule %r/-/, Operator
        rule %r/\d+\.\d+/, Num::Float
        rule %r/\d+/, Num::Integer
      end

      state :variable do
        rule %r/(\.)(\s*)(first|last|size)\b(?![?!\/])/ do
          groups Punctuation, Text::Whitespace, Name::Function
        end

        rule %r/\.(?= *\w)|\[|\]/, Punctuation
        rule %r/(empty|blank|(for|tablerow)loop\.(parentloop\.)*\w+)\b(?![?!\/])/, Name::Builtin
        rule %r/[a-zA-Z_][\w-]*\b-?(?![?!\/])/, Name::Variable
        rule %r/\S+/, Text
      end
    end
  end
end
