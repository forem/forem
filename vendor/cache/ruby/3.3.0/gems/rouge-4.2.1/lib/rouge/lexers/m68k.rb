# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class M68k < RegexLexer
      tag 'm68k'

      title "M68k"
      desc "Motorola 68k Assembler"

      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      def self.keywords
        @keywords ||= Set.new %w(
          abcd add adda addi addq addx and andi asl asr

          bcc bcs beq bge bgt bhi ble bls blt bmi bne bpl bvc bvs bhs blo
          bchg bclr bfchg bfclr bfests bfextu bfffo bfins bfset bftst bkpt bra bse bsr btst

          callm cas cas2 chk chk2 clr cmp cmpa cmpi cmpm cmp2

          dbcc dbcs dbeq dbge dbgt dbhi dble dbls dblt dbmi dbne dbpl dbvc dbvs dbhs dblo
          dbra dbf dbt divs divsl divu divul

          eor eori exg ext extb

          illegal jmp jsr lea link lsl lsr

          move movea move16 movem movep moveq muls mulu

          nbcd neg negx nop not or ori

          pack pea rol ror roxl roxr rtd rtm rtr rts

          sbcd

          seq sne spl smi svc svs st sf sge sgt sle slt scc shi sls scs shs slo
          sub suba subi subq subx swap

          tas trap trapcc TODO trapv tst

          unlk unpk eori
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          dc ds dcb
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          include incdir incbin end endf endfunc endmain endproc fpu func machine main mmu opword proc set opt section
          rept endr
          ifeq ifne ifgt ifge iflt ifle iif ifd ifnd ifc ifnc elseif else endc
          even cnop fail machine
          output radix __G2 __LK
          list nolist plen llen ttl subttl spc page listchar format
          equ equenv equr set reg
          rsreset rsset offset
          cargs
          fequ.s fequ.d fequ.x fequ.p fequ.w fequ.l fopt
          macro endm mexit narg
        )
      end

      def self.builtins
        @builtins ||=Set.new %w(
          d0 d1 d2 d3 d4 d5 d6 d7
          a0 a1 a2 a3 a4 a5 a6 a7 a7'
          pc usp ssp ccr
        )
      end

      start { push :expr_bol }

      state :expr_bol do
        mixin :inline_whitespace
        rule(//) { pop! }
      end

      state :inline_whitespace do
        rule %r/\s+/, Text
      end

      state :whitespace do
        rule %r/\n+/m, Text, :expr_bol
        rule %r(^\*(\\.|.)*?$), Comment::Single, :expr_bol
        rule %r(;(\\.|.)*?$), Comment::Single, :expr_bol
        mixin :inline_whitespace
      end

      state :root do
        rule(//) { push :statements }
      end

      state :statements do
        mixin :whitespace
        rule %r/"/, Str, :string
        rule %r/#/, Name::Decorator
        rule %r/^\.?[a-zA-Z0-9_]+:?/, Name::Label
        rule %r/\.[bswl]\s/i, Name::Decorator
        rule %r('(\\.|\\[0-7]{1,3}|\\x[a-f0-9]{1,2}|[^\\'\n])')i, Str::Char
        rule %r/\$[0-9a-f]+/i, Num::Hex
        rule %r/@[0-8]+/i, Num::Oct
        rule %r/%[01]+/i, Num::Bin
        rule %r/\d+/i, Num::Integer
        rule %r([*~&+=\|?:<>/-]), Operator
        rule %r/\\./, Comment::Preproc
        rule %r/[(),.]/, Punctuation
        rule %r/\[[a-zA-Z0-9]*\]/, Punctuation

        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name.downcase
            token Keyword
          elsif self.class.keywords_type.include? name.downcase
            token Keyword::Type
          elsif self.class.reserved.include? name.downcase
            token Keyword::Reserved
          elsif self.class.builtins.include? name.downcase
            token Name::Builtin
          elsif name =~ /[a-zA-Z0-9]+/
            token Name::Variable
          else
            token Name
          end
        end
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\\n/, Str
        rule %r/\\/, Str # stray backslash
      end
    end
  end
end
