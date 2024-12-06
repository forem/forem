# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Smalltalk < RegexLexer
      title "Smalltalk"
      desc 'The Smalltalk programming language'

      tag 'smalltalk'
      aliases 'st', 'squeak'
      filenames '*.st'
      mimetypes 'text/x-smalltalk'

      ops = %r([-+*/\\~<>=|&!?,@%])

      state :root do
        rule %r/(<)(\w+:)(.*?)(>)/ do
          groups Punctuation, Keyword, Text, Punctuation
        end

        # mixin :squeak_fileout
        mixin :whitespaces
        mixin :method_definition
        rule %r/([|])([\w\s]*)([|])/ do
          groups Punctuation, Name::Variable, Punctuation
        end
        mixin :objects
        rule %r/\^|:=|_/, Operator

        rule %r/[)}\]]/, Punctuation, :after_object
        rule %r/[({\[!]/, Punctuation
      end

      state :method_definition do
        rule %r/([a-z]\w*:)(\s*)(\w+)/i do
          groups Name::Function, Text, Name::Variable
        end

        rule %r/^(\s*)(\b[a-z]\w*\b)(\s*)$/i do
          groups Text, Name::Function, Text
        end

        rule %r(^(\s*)(#{ops}+)(\s*)(\w+)(\s*)$) do
          groups Text, Name::Function, Text, Name::Variable, Text
        end
      end

      state :block_variables do
        mixin :whitespaces
        rule %r/(:)(\s*)(\w+)/ do
          groups Operator, Text, Name::Variable
        end

        rule %r/[|]/, Punctuation, :pop!

        rule(//) { pop! }
      end

      state :literals do
        rule %r/'(''|.)*?'/m, Str, :after_object
        rule %r/[$]./, Str::Char, :after_object
        rule %r/#[(]/, Str::Symbol, :parenth
        rule %r/(\d+r)?-?\d+(\.\d+)?(e-?\d+)?/,
          Num, :after_object
        rule %r/#("[^"]*"|#{ops}+|[\w:]+)/,
          Str::Symbol, :after_object
      end

      state :parenth do
        rule %r/[)]/ do
          token Str::Symbol
          goto :after_object
        end

        mixin :inner_parenth
      end

      state :inner_parenth do
        rule %r/#[(]/, Str::Symbol, :inner_parenth
        rule %r/[)]/, Str::Symbol, :pop!
        mixin :whitespaces
        mixin :literals
        rule %r/(#{ops}|[\w:])+/, Str::Symbol
      end

      state :whitespaces do
        rule %r/! !$/, Keyword # squeak chunk delimiter
        rule %r/\s+/m, Text
        rule %r/".*?"/m, Comment
      end

      state :objects do
        rule %r/\[/, Punctuation, :block_variables
        rule %r/(self|super|true|false|nil|thisContext)\b/,
          Name::Builtin::Pseudo, :after_object
        rule %r/[A-Z]\w*(?!:)\b/, Name::Class, :after_object
        rule %r/[a-z]\w*(?!:)\b/, Name::Variable, :after_object
        mixin :literals
      end

      state :after_object do
        mixin :whitespaces
        rule %r/(ifTrue|ifFalse|whileTrue|whileFalse|timesRepeat):/,
          Name::Builtin, :pop!
        rule %r/new(?!:)\b/, Name::Builtin
        rule %r/:=|_/, Operator, :pop!
        rule %r/[a-z]+\w*:/i, Name::Function, :pop!
        rule %r/[a-z]+\w*/i, Name::Function
        rule %r/#{ops}+/, Name::Function, :pop!
        rule %r/[.]/, Punctuation, :pop!
        rule %r/;/, Punctuation
        rule(//) { pop! }
      end
    end
  end
end
