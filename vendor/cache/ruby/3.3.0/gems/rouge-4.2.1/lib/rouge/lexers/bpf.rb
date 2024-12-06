# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class BPF < RegexLexer
      title "BPF"
      desc "BPF bytecode syntax"
      tag 'bpf'

      TYPE_KEYWORDS = %w(
        u8 u16 u32 u64 s8 s16 s32 s64 ll
      ).join('|')

      MISC_KEYWORDS = %w(
        be16 be32 be64 le16 le32 le64 bswap16 bswap32 bswap64 exit lock map
      ).join('|')

      state :root do
        # Line numbers and hexadecimal output from bpftool/objdump
        rule %r/(\d+)(:)(\s+)(\(\h{2}\))/i do
          groups Generic::Lineno, Punctuation, Text::Whitespace, Generic
        end
        rule %r/(\d+)(:)(\s+)((?:\h{2} ){8})/i do
          groups Generic::Lineno, Punctuation, Text::Whitespace, Generic
        end
        rule %r/(\d+)(:)(\s+)/i do
          groups Generic::Lineno, Punctuation, Text::Whitespace
        end

        # Calls to helpers
        rule %r/(call)(\s+)(\d+)/i do
          groups Keyword, Text::Whitespace, Literal::Number::Integer
        end
        rule %r/(call)(\s+)(\w+)(?:(#)(\d+))?/i do
          groups Keyword, Text::Whitespace, Name::Builtin, Punctuation, Literal::Number::Integer
        end

        # Unconditional jumps
        rule %r/(gotol?)(\s*)([-+]0x\w+)?([-+]\d+)?(\s*)(<?\w+>?)/i do
          groups Keyword, Text::Whitespace, Literal::Number::Hex, Literal::Number::Integer, Text::Whitespace, Name::Label
        end

        # Conditional jumps
        rule %r/(if)(\s+)([rw]\d+)(\s*)([s!=<>]+)(\s*)(0x\h+|[-]?\d+)(\s*)(gotol?)(\s*)([-+]0x\w+)?([-+]\d+)?(\s*)(<?\w+>?)/i do
          groups Keyword, Text::Whitespace, Name, Text::Whitespace, Operator, Text::Whitespace, Literal::Number, Text::Whitespace, Keyword, Text::Whitespace, Literal::Number::Hex, Literal::Number::Integer, Text::Whitespace, Name::Label
        end
        rule %r/(if)(\s+)([rw]\d+)(\s*)([s!=<>]+)(\s*)([rw]\d+)(\s*)(gotol?)(\s*)([-+]0x\w+)?([-+]\d+)?(\s*)(<?\w+>?)/i do
          groups Keyword, Text::Whitespace, Name, Text::Whitespace, Operator, Text::Whitespace, Name, Text::Whitespace, Keyword, Text::Whitespace, Literal::Number::Hex, Literal::Number::Integer, Text::Whitespace, Name::Label
        end

        # Dereferences
        rule %r/(\*)(\s*)(\()(#{TYPE_KEYWORDS})(\s*)(\*)(\))/i do
          groups Operator, Text::Whitespace, Punctuation, Keyword::Type, Text::Whitespace, Operator, Punctuation
          push :address
        end

        # Operators
        rule %r/[+-\/\*&|><^s]{0,3}=/i, Operator

        # Registers
        rule %r/([+-]?)([rw]\d+)/i do
          groups Punctuation, Name
        end

        # Comments
        rule %r/\/\//, Comment::Single, :linecomment
        rule %r/\/\*/, Comment::Multiline, :multilinescomment

        rule %r/#{MISC_KEYWORDS}/i, Keyword

        # Literals and global objects (maps) refered by name
        rule %r/([-]?0x\h+|[-]?\d+)(\s*)(ll)?/i do
          groups Literal::Number, Text::Whitespace, Keyword::Type
        end
        rule %r/(\w+)(\s*)(ll)/i do
          groups Name, Text::Whitespace, Keyword::Type
        end

        # Labels
        rule %r/(\w+)(\s*)(:)/i do
          groups Name::Label, Text::Whitespace, Punctuation
        end

        rule %r{.}m, Text
      end

      state :address do
        # Address is offset from register
        rule %r/(\()([rw]\d+)(\s*)([+-])(\s*)(\d+)(\))/i do
          groups Punctuation, Name, Text::Whitespace, Operator, Text::Whitespace, Literal::Number::Integer, Punctuation
          pop!
        end

        # Address is array subscript
        rule %r/(\w+)(\[)(\d+)(\])/i do
          groups Name, Punctuation, Literal::Number::Integer, Punctuation
          pop!
        end
        rule %r/(\w+)(\[)([rw]\d+)(\])/i do
          groups Name, Punctuation, Name, Punctuation
          pop!
        end
      end

      state :linecomment do
        rule %r/\n/, Comment::Single, :pop!
        rule %r/.+/, Comment::Single
      end

      state :multilinescomment do
        rule %r/\*\//, Comment::Multiline, :pop!
        rule %r/([^\*\/]+)/, Comment::Multiline
        rule %r/([\*\/])/, Comment::Multiline
      end
    end
  end
end
