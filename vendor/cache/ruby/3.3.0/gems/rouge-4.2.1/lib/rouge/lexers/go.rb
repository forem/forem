# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Go < RegexLexer
      title "Go"
      desc 'The Go programming language (http://golang.org)'
      tag 'go'
      aliases 'go', 'golang'
      filenames '*.go'

      mimetypes 'text/x-go', 'application/x-go'

      # Characters

      WHITE_SPACE            = /\s+/

      NEWLINE                = /\n/
      UNICODE_CHAR           = /[^\n]/
      UNICODE_LETTER         = /[[:alpha:]]/
      UNICODE_DIGIT          = /[[:digit:]]/

      # Letters and digits

      LETTER                 = /#{UNICODE_LETTER}|_/
      DECIMAL_DIGIT          = /[0-9]/
      OCTAL_DIGIT            = /[0-7]/
      HEX_DIGIT              = /[0-9A-Fa-f]/

      # Comments

      LINE_COMMENT           = /\/\/(?:(?!#{NEWLINE}).)*/
      GENERAL_COMMENT        = /\/\*(?:(?!\*\/).)*\*\//m
      COMMENT                = /#{LINE_COMMENT}|#{GENERAL_COMMENT}/

      # Keywords

      KEYWORD                = /\b(?:
                                 break       | default     | func
                               | interface   | select      | case
                               | defer       | go          | map
                               | struct      | chan        | else
                               | goto        | package     | switch
                               | const       | fallthrough | if
                               | range       | type        | continue
                               | for         | import      | return
                               | var
                               )\b/x

      # Identifiers

      IDENTIFIER             = / (?!#{KEYWORD})
                                 #{LETTER}(?:#{LETTER}|#{UNICODE_DIGIT})* /x

      # Operators and delimiters

      OPERATOR               = / \+=    | \+\+   | \+     | &\^=   | &\^
                               | &=     | &&     | &      | ==     | =
                               | \!=    | \!     | -=     | --     | -
                               | \|=    | \|\|   | \|     | <=     | <-
                               | <<=    | <<     | <      | \*=    | \*
                               | \^=    | \^     | >>=    | >>     | >=
                               | >      | \/     | \/=    | :=     | %
                               | %=     | \.\.\. | \.     | :
                               /x

      SEPARATOR              = / \(     | \)     | \[     | \]     | \{
                               | \}     | ,      | ;
                               /x

      # Integer literals

      DECIMAL_LIT            = /[0-9]#{DECIMAL_DIGIT}*/
      OCTAL_LIT              = /0#{OCTAL_DIGIT}*/
      HEX_LIT                = /0[xX]#{HEX_DIGIT}+/
      INT_LIT                = /#{HEX_LIT}|#{DECIMAL_LIT}|#{OCTAL_LIT}/

      # Floating-point literals

      DECIMALS               = /#{DECIMAL_DIGIT}+/
      EXPONENT               = /[eE][+\-]?#{DECIMALS}/
      FLOAT_LIT              = / #{DECIMALS} \. #{DECIMALS}? #{EXPONENT}?
                               | #{DECIMALS} #{EXPONENT}
                               | \. #{DECIMALS} #{EXPONENT}?
                               /x

      # Imaginary literals

      IMAGINARY_LIT          = /(?:#{DECIMALS}|#{FLOAT_LIT})i/

      # Rune literals

      ESCAPED_CHAR           = /\\[abfnrtv\\'"]/
      LITTLE_U_VALUE         = /\\u#{HEX_DIGIT}{4}/
      BIG_U_VALUE            = /\\U#{HEX_DIGIT}{8}/
      UNICODE_VALUE          = / #{UNICODE_CHAR} | #{LITTLE_U_VALUE}
                               | #{BIG_U_VALUE}  | #{ESCAPED_CHAR}
                               /x
      OCTAL_BYTE_VALUE       = /\\#{OCTAL_DIGIT}{3}/
      HEX_BYTE_VALUE         = /\\x#{HEX_DIGIT}{2}/
      BYTE_VALUE             = /#{OCTAL_BYTE_VALUE}|#{HEX_BYTE_VALUE}/
      CHAR_LIT               = /'(?:#{UNICODE_VALUE}|#{BYTE_VALUE})'/
      ESCAPE_SEQUENCE        = / #{ESCAPED_CHAR}
                               | #{LITTLE_U_VALUE}
                               | #{BIG_U_VALUE}
                               | #{HEX_BYTE_VALUE}
                               /x

      # String literals

      RAW_STRING_LIT         = /`(?:#{UNICODE_CHAR}|#{NEWLINE})*`/
      INTERPRETED_STRING_LIT = / "(?: (?!")
                                      (?: #{UNICODE_VALUE} | #{BYTE_VALUE} )
                                  )*" /x
      STRING_LIT             = /#{RAW_STRING_LIT}|#{INTERPRETED_STRING_LIT}/

      # Predeclared identifiers

      PREDECLARED_TYPES      = /\b(?:
                                 bool       | byte       | complex64
                               | complex128 | error      | float32
                               | float64    | int8       | int16
                               | int32      | int64      | int
                               | rune       | string     | uint8
                               | uint16     | uint32     | uint64
                               | uintptr    | uint
      	                       )\b/x

      PREDECLARED_CONSTANTS  = /\b(?:true|false|iota|nil)\b/

      PREDECLARED_FUNCTIONS  = /\b(?:
                                 append  | cap     | close   | complex
                               | copy    | delete  | imag    | len
                               | make    | new     | panic   | print
                               | println | real    | recover
                               )\b/x

      state :simple_tokens do
        rule(COMMENT,               Comment)
        rule(KEYWORD,               Keyword)
        rule(PREDECLARED_TYPES,     Keyword::Type)
        rule(PREDECLARED_FUNCTIONS, Name::Builtin)
        rule(PREDECLARED_CONSTANTS, Name::Constant)
        rule(IMAGINARY_LIT,         Num)
        rule(FLOAT_LIT,             Num)
        rule(INT_LIT,               Num)
        rule(CHAR_LIT,              Str::Char)
        rule(OPERATOR,              Operator)
        rule(SEPARATOR,             Punctuation)
        rule(IDENTIFIER,            Name)
        rule(WHITE_SPACE,           Text)
      end

      state :root do
        mixin :simple_tokens

        rule(/`/,             Str, :raw_string)
        rule(/"/,             Str, :interpreted_string)
      end

      state :interpreted_string do
        rule(ESCAPE_SEQUENCE, Str::Escape)
        rule(/\\./,           Error)
        rule(/"/,             Str, :pop!)
        rule(/[^"\\]+/,       Str)
      end

      state :raw_string do
        rule(/`/,             Str, :pop!)
        rule(/[^`]+/m,        Str)
      end
    end
  end
end
