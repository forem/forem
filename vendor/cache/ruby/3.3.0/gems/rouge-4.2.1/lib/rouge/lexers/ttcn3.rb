# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class TTCN3 < RegexLexer
      title "TTCN3"
      desc "The TTCN3 programming language (ttcn-3.org)"

      tag 'ttcn3'
      filenames '*.ttcn', '*.ttcn3'
      mimetypes 'text/x-ttcn3', 'text/x-ttcn'

      def self.keywords
        @keywords ||= %w(
          module import group type port component signature external
          execute const template function altstep testcase var timer if
          else select case for while do label goto start stop return
          break int2char int2unichar int2bit int2enum int2hex int2oct
          int2str int2float float2int char2int char2oct unichar2int
          unichar2oct bit2int bit2hex bit2oct bit2str hex2int hex2bit
          hex2oct hex2str oct2int oct2bit oct2hex oct2str oct2char
          oct2unichar str2int str2hex str2oct str2float enum2int
          any2unistr lengthof sizeof ispresent ischosen isvalue isbound
          istemplatekind regexp substr replace encvalue decvalue
          encvalue_unichar decvalue_unichar encvalue_o decvalue_o
          get_stringencoding remove_bom rnd hostid send receive
          setverdict
        )
      end

      def self.reserved
        @reserved ||= %w(
          all alt apply assert at configuration conjunct const control
          delta deterministic disjunct duration fail finished fuzzy from
          history implies inconc inv lazy mod mode notinv now omit
          onentry onexit par pass prev realtime seq setstate static
          stepsize stream timestamp until values wait
        )
      end

      def self.types
        @types ||= %w(
          anytype address boolean bitstring charstring hexstring octetstring
          component enumerated float integer port record set of union universal
        )
      end

      id = /[a-zA-Z_]\w*/
      digit = /\d_+\d|\d/
      bin_digit = /[01]_+[01]|[01]/
      oct_digit = /[0-7]_+[0-7]|[0-7]/
      hex_digit = /\h_+\h|\h/

      state :statements do
        rule %r/\n+/m, Text
        rule %r/[ \t\r]+/, Text
        rule %r/\\\n/, Text # line continuation

        rule %r(//(\\.|.)*?$), Comment::Single
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline

        rule %r/"/, Str, :string
        rule %r/'(?:\\.|[^\\]|\\u[0-9a-f]{4})'/, Str::Char
        
        rule %r/#{digit}+\.#{digit}+([eE]#{digit}+)?[fd]?/i, Num::Float
        rule %r/'#{bin_digit}+'B/i, Num::Bin
        rule %r/'#{hex_digit}+'H/i, Num::Hex
        rule %r/'#{oct_digit}+'O/i, Num::Oct
        rule %r/#{digit}+/i, Num::Integer

        rule %r([~!%^&*+:=\|?<>/-]), Operator
        rule %r/[()\[\]{},.;:]/, Punctuation

        rule %r/(?:true|false|null)\b/, Name::Builtin

        rule id do |m|
          name = m[0]
          if self.class.keywords.include? name
            token Keyword
          elsif self.class.types.include? name
            token Keyword::Type
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          else
            token Name
          end
        end
      end

      state :root do
        rule %r/module\b/, Keyword::Declaration, :module
        rule %r/import\b/, Keyword::Namespace, :import

        mixin :statements
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\\n/, Str
        rule %r/\\/, Str # stray backslash
      end

      state :module do
        rule %r/\s+/m, Text
        rule id, Name::Class, :pop!
      end

      state :import do
        rule %r/\s+/m, Text
        rule %r/[\w.]+\*?/, Name::Namespace, :pop!
      end
    end
  end
end
