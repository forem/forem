# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class NesAsm < RegexLexer
      title "NesAsm"
      desc "Nesasm3 assembly (6502 asm)"
      tag 'nesasm'
      aliases 'nes'
      filenames '*.nesasm'

      def self.keywords
        @keywords ||= %w(
          ADC AND ASL BIT BRK CMP CPX CPY DEC EOR INC JMP JSR LDA LDX LDY LSR
          NOP ORA ROL ROR RTI RTS SBC STA STX STY TAX TXA DEX INX TAY TYA DEY
          INY BPL BMI BVC BVS BCC BCS BNE BEQ CLC SEC CLI SEI CLV CLD SED TXS
          TSX PHA PLA PHP PLP
        )
      end

      def self.keywords_type
        @keywords_type ||= %w(
          DB DW BYTE WORD 
        )
      end

      def self.keywords_reserved
        @keywords_reserved ||= %w(
          INCBIN INCLUDE ORG BANK RSSET RS MACRO ENDM DS PROC ENDP PROCGROUP
          ENDPROCGROUP INCCHR DEFCHR ZP BSS CODE DATA IF IFDEF IFNDEF ELSE
          ENDIF FAIL INESPRG INESCHR INESMAP INESMIR FUNC
        )
      end
      
      state :root do
        rule %r/\s+/m, Text
        rule %r(;.*), Comment::Single

        rule %r/[\(\)\,\.\[\]]/, Punctuation 
        rule %r/\#?\%[0-1]+/, Num::Bin # #%00110011 %00110011
        rule %r/\#?\$\h+/, Num::Hex  # $1f #$1f
        rule %r/\#?\d+/, Num # 10 #10
        rule %r([~&*+=\|?:<>/-]), Operator

        rule %r/\#?\w+:?/i do |m|
          name = m[0].upcase
          
          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.keywords_reserved.include? name
            token Keyword::Reserved
          else
            token Name::Function
          end
        end

        rule %r/\#?(?:LOW|HIGH)\(.*\)/i, Keyword::Reserved # LOW() #HIGH()
        
        rule %r/\#\(/, Punctuation # #()

        rule %r/"/, Str, :string

        rule %r/'\w'/, Str::Char # 'A' for example
        
        rule %r/\\\??[\d@#]/, Name::Builtin # builtin parameters for use inside macros and functions:   \1-\9 , \?1-\?9 , \# , \@
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\"?/, Str::Escape
        rule %r/[^"\\]+/m, Str
      end
    end
  end
end
