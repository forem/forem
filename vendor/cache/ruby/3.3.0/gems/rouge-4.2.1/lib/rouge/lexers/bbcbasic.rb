# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class BBCBASIC < RegexLexer
      title "BBCBASIC"
      desc "BBC BASIC syntax"
      tag 'bbcbasic'
      filenames '*,fd1'

      def self.punctuation
        @punctuation ||= %w(
          [,;'~] SPC TAB
        )
      end

      def self.function
        @function ||= %w(
          ABS ACS ADVAL ASC ASN ATN BEATS BEAT BGET# CHR\$ COS COUNT DEG DIM
          EOF# ERL ERR EVAL EXP EXT# FN GET\$# GET\$ GET HIMEM INKEY\$ INKEY
          INSTR INT LEFT\$ LEN LN LOG LOMEM MID\$ OPENIN OPENOUT OPENUP PAGE
          POINT POS PTR# RAD REPORT\$ RIGHT\$ RND SGN SIN SQR STR\$ STRING\$ SUM
          SUMLEN TAN TEMPO TIME\$ TIME TOP USR VAL VPOS
        )
      end

      def self.statement
        @statement ||= %w(
          BEATS BPUT# CALL CASE CHAIN CLEAR CLG CLOSE# CLS COLOR COLOUR DATA
          ELSE ENDCASE ENDIF ENDPROC ENDWHILE END ENVELOPE FOR GCOL GOSUB GOTO
          IF INSTALL LET LIBRARY MODE NEXT OFF OF ON ORIGIN OSCI OTHERWISE
          OVERLAY PLOT PRINT# PRINT PROC QUIT READ REPEAT REPORT RETURN SOUND
          STEP STEREO STOP SWAP SYS THEN TINT TO VDU VOICES VOICE UNTIL WAIT
          WHEN WHILE WIDTH
        )
      end

      def self.operator
        @operator ||= %w(
          << <= <> < >= >>> >> > [-!$()*+/=?^|] AND DIV EOR MOD NOT OR
        )
      end

      def self.constant
        @constant ||= %w(
          FALSE TRUE
        )
      end

      state :expression do
        rule %r/#{BBCBASIC.function.join('|')}/o, Name::Builtin  # function or pseudo-variable
        rule %r/#{BBCBASIC.operator.join('|')}/o, Operator
        rule %r/#{BBCBASIC.constant.join('|')}/o, Name::Constant
        rule %r/"[^"]*"/o, Literal::String
        rule %r/[a-z_`][\w`]*[$%]?/io, Name::Variable
        rule %r/@%/o, Name::Variable
        rule %r/[\d.]+/o, Literal::Number
        rule %r/%[01]+/o, Literal::Number::Bin
        rule %r/&[\h]+/o, Literal::Number::Hex
      end

      state :root do
        rule %r/(:+)( *)(\*)(.*)/ do
          groups Punctuation, Text, Keyword, Text # CLI command
        end
        rule %r/(\n+ *)(\*)(.*)/ do
          groups Text, Keyword, Text # CLI command
        end
        rule %r/(ELSE|OTHERWISE|REPEAT|THEN)( *)(\*)(.*)/ do
          groups Keyword, Text, Keyword, Text # CLI command
        end
        rule %r/[ \n]+/o, Text
        rule %r/:+/o, Punctuation
        rule %r/[\[]/o, Keyword, :assembly1
        rule %r/REM *>.*/o, Comment::Special
        rule %r/REM.*/o, Comment
        rule %r/(?:#{BBCBASIC.statement.join('|')}|CIRCLE(?: *FILL)?|DEF *(?:FN|PROC)|DRAW(?: *BY)?|DIM(?!\()|ELLIPSE(?: *FILL)?|ERROR(?: *EXT)?|FILL(?: *BY)?|INPUT(?:#| *LINE)?|LINE(?: *INPUT)?|LOCAL(?: *DATA| *ERROR)?|MOUSE(?: *COLOUR| *OFF| *ON| *RECTANGLE| *STEP| *TO)?|MOVE(?: *BY)?|ON(?! *ERROR)|ON *ERROR *(?:LOCAL|OFF)?|POINT(?: *BY)?(?!\()|RECTANGE(?: *FILL)?|RESTORE(?: *DATA| *ERROR)?|TRACE(?: *CLOSE| *ENDPROC| *OFF| *STEP(?: *FN| *ON| *PROC)?| *TO)?)/o, Keyword
        mixin :expression
        rule %r/#{BBCBASIC.punctuation.join('|')}/o, Punctuation
      end

      # Assembly statements are parsed as
      # {label} {directive|opcode |']' {expressions}} {comment}
      # Technically, you don't need whitespace between opcodes and arguments,
      # but this is rare in uncrunched source and trying to enumerate all
      # possible opcodes here is impractical so we colour it as though
      # the whitespace is required. Opcodes and directives can only easily be
      # distinguished from the symbols that make up expressions by looking at
      # their position within the statement. Similarly, ']' is treated as a
      # keyword at the start of a statement or as punctuation elsewhere. This
      # requires a two-state state machine.

      state :assembly1 do
        rule %r/ +/o, Text
        rule %r/]/o, Keyword, :pop!
        rule %r/[:\n]/o, Punctuation
        rule %r/\.[a-z_`][\w`]*%? */io, Name::Label
        rule %r/(?:REM|;)[^:\n]*/o, Comment
        rule %r/[^ :\n]+/o, Keyword, :assembly2
      end

      state :assembly2 do
        rule %r/ +/o, Text
        rule %r/[:\n]/o, Punctuation, :pop!
        rule %r/(?:REM|;)[^:\n]*/o, Comment, :pop!
        mixin :expression
        rule %r/[!#,@\[\]^{}]/, Punctuation
      end
    end
  end
end
