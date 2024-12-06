# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# Based on Chroma's NASM lexer implementation
# https://github.com/alecthomas/chroma/blob/498eaa690f5ac6ab0e3d6f46237e547a8935cdc7/lexers/n/nasm.go
module Rouge
  module Lexers
    class Nasm < RegexLexer
      title "Nasm"
      desc "Netwide Assembler"

      tag 'nasm'
      filenames '*.asm'
      mimetypes 'text/x-nasm'

      state :root do
        rule %r/^\s*%/, Comment::Preproc, :preproc

        mixin :whitespace
        mixin :punctuation

        rule %r/[a-z$._?][\w$.?#@~]*:/i, Name::Label

        rule %r/([a-z$._?][\w$.?#@~]*)(\s+)(equ)/i do
          groups Name::Constant, Keyword::Declaration, Keyword::Declaration
          push :instruction_args
        end
        rule %r/BITS|USE16|USE32|SECTION|SEGMENT|ABSOLUTE|EXTERN|GLOBAL|ORG|ALIGN|STRUC|ENDSTRUC|COMMON|CPU|GROUP|UPPERCASE|IMPORT|EXPORT|LIBRARY|MODULE/, Keyword, :instruction_args
        rule %r/(?:res|d)[bwdqt]|times/i, Keyword::Declaration, :instruction_args
        rule %r/[a-z$._?][\w$.?#@~]*/i, Name::Function, :instruction_args

        rule %r/[\r\n]+/, Text
      end

      state :instruction_args do
        rule %r/"(\\\\"|[^"\\n])*"|'(\\\\'|[^'\\n])*'|`(\\\\`|[^`\\n])*`/, Str
        rule %r/(?:0x[\da-f]+|$0[\da-f]*|\d+[\da-f]*h)/i, Num::Hex
        rule %r/[0-7]+q/i, Num::Oct
        rule %r/[01]+b/i, Num::Bin
        rule %r/\d+\.e?\d+/i, Num::Float
        rule %r/\d+/, Num::Integer

        mixin :punctuation

        rule %r/r\d[0-5]?[bwd]|[a-d][lh]|[er]?[a-d]x|[er]?[sb]p|[er]?[sd]i|[c-gs]s|st[0-7]|mm[0-7]|cr[0-4]|dr[0-367]|tr[3-7]/i, Name::Builtin
        rule %r/[a-z$._?][\w$.?#@~]*/i, Name::Variable
        rule %r/[\r\n]+/, Text, :pop!

        mixin :whitespace
      end

      state :preproc do
        rule %r/[^;\n]+/, Comment::Preproc
        rule %r/;.*?\n/, Comment::Single, :pop!
        rule %r/\n/, Comment::Preproc, :pop!
      end

      state :whitespace do
        rule %r/\n/, Text
        rule %r/[ \t]+/, Text
        rule %r/;.*/, Comment::Single
      end

      state :punctuation do
        rule %r/[,():\[\]]+/, Punctuation
        rule %r/[&|^<>+*\/%~-]+/, Operator
        rule %r/\$+/, Keyword::Constant
        rule %r/seg|wrt|strict/i, Operator::Word
        rule %r/byte|[dq]?word/i, Keyword::Type
      end
    end
  end
end
