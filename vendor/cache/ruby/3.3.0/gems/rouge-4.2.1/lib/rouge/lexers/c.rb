# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class C < RegexLexer
      tag 'c'
      filenames '*.c', '*.h', '*.idc'
      mimetypes 'text/x-chdr', 'text/x-csrc'

      title "C"
      desc "The C programming language"

      # optional comment or whitespace
      ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      def self.keywords
        @keywords ||= Set.new %w(
          auto break case const continue default do else enum extern
          for goto if register restricted return sizeof static struct
          switch typedef union volatile virtual while

          _Alignas _Alignof _Atomic _Generic _Imaginary
          _Noreturn _Static_assert _Thread_local
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          int long float short double char unsigned signed void

          jmp_buf FILE DIR div_t ldiv_t mbstate_t sig_atomic_t fpos_t
          clock_t time_t va_list size_t ssize_t off_t wchar_t ptrdiff_t
          wctrans_t wint_t wctype_t

          _Bool _Complex int8_t int16_t int32_t int64_t
          uint8_t uint16_t uint32_t uint64_t int_least8_t
          int_least16_t int_least32_t int_least64_t
          uint_least8_t uint_least16_t uint_least32_t
          uint_least64_t int_fast8_t int_fast16_t int_fast32_t
          int_fast64_t uint_fast8_t uint_fast16_t uint_fast32_t
          uint_fast64_t intptr_t uintptr_t intmax_t
          uintmax_t

          char16_t char32_t
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          __asm __int8 __based __except __int16 __stdcall __cdecl
          __fastcall __int32 __declspec __finally __int61 __try __leave
          inline _inline __inline naked _naked __naked restrict _restrict
          __restrict thread _thread __thread typename _typename __typename
        )
      end

      def self.builtins
        @builtins ||= []
      end

      start { push :bol }

      state :expr_bol do
        mixin :inline_whitespace

        rule %r/#if\s0/, Comment, :if_0
        rule %r/#/, Comment::Preproc, :macro

        rule(//) { pop! }
      end

      # :expr_bol is the same as :bol but without labels, since
      # labels can only appear at the beginning of a statement.
      state :bol do
        rule %r/#{id}:(?!:)/, Name::Label
        mixin :expr_bol
      end

      state :inline_whitespace do
        rule %r/[ \t\r]+/, Text
        rule %r/\\\n/, Text # line continuation
        rule %r(/(\\\n)?[*].*?[*](\\\n)?/)m, Comment::Multiline
      end

      state :whitespace do
        rule %r/\n+/m, Text, :bol
        rule %r(//(\\.|.)*?$), Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :expr_whitespace do
        rule %r/\n+/m, Text, :expr_bol
        mixin :whitespace
      end

      state :statements do
        mixin :whitespace
        rule %r/(u8|u|U|L)?"/, Str, :string
        rule %r((u8|u|U|L)?'(\\.|\\[0-7]{1,3}|\\x[a-f0-9]{1,2}|[^\\'\n])')i, Str::Char
        rule %r((\d+[.]\d*|[.]?\d+)e[+-]?\d+[lu]*)i, Num::Float
        rule %r(\d+e[+-]?\d+[lu]*)i, Num::Float
        rule %r/0x[0-9a-f]+[lu]*/i, Num::Hex
        rule %r/0[0-7]+[lu]*/i, Num::Oct
        rule %r/\d+[lu]*/i, Num::Integer
        rule %r(\*/), Error
        rule %r([~!%^&*+=\|?:<>/-]), Operator
        rule %r/[()\[\],.;]/, Punctuation
        rule %r/\bcase\b/, Keyword, :case
        rule %r/(?:true|false|NULL)\b/, Name::Builtin
        rule id do |m|
          name = m[0]

          if self.class.keywords.include? name
            token Keyword
          elsif self.class.keywords_type.include? name
            token Keyword::Type
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          elsif self.class.builtins.include? name
            token Name::Builtin
          else
            token Name
          end
        end
      end

      state :case do
        rule %r/:/, Punctuation, :pop!
        mixin :statements
      end

      state :root do
        mixin :expr_whitespace
        rule %r(
          ([\w*\s]+?[\s*]) # return arguments
          (#{id})          # function name
          (\s*\([^;]*?\))  # signature
          (#{ws}?)({|;)    # open brace or semicolon
        )mx do |m|
          # TODO: do this better.
          recurse m[1]
          token Name::Function, m[2]
          recurse m[3]
          recurse m[4]
          token Punctuation, m[5]
          if m[5] == ?{
            push :function
          end
        end
        rule %r/\{/, Punctuation, :function
        mixin :statements
      end

      state :function do
        mixin :whitespace
        mixin :statements
        rule %r/;/, Punctuation
        rule %r/{/, Punctuation, :function
        rule %r/}/, Punctuation, :pop!
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\([\\abfnrtv"']|x[a-fA-F0-9]{2,4}|[0-7]{1,3})/, Str::Escape
        rule %r/[^\\"\n]+/, Str
        rule %r/\\\n/, Str
        rule %r/\\/, Str # stray backslash
      end

      state :macro do
        mixin :include
        rule %r([^/\n\\]+), Comment::Preproc
        rule %r/\\./m, Comment::Preproc
        mixin :inline_whitespace
        rule %r(/), Comment::Preproc
        # NB: pop! goes back to :bol
        rule %r/\n/, Comment::Preproc, :pop!
      end

      state :include do
        rule %r/(include)(\s*)(<[^>]+>)([^\n]*)/ do
          groups Comment::Preproc, Text, Comment::PreprocFile, Comment::Single
        end
        rule %r/(include)(\s*)("[^"]+")([^\n]*)/ do
          groups Comment::Preproc, Text, Comment::PreprocFile, Comment::Single
        end
      end

      state :if_0 do
        # NB: no \b here, to cover #ifdef and #ifndef
        rule %r/^\s*#if/, Comment, :if_0
        rule %r/^\s*#\s*el(?:se|if)/, Comment, :pop!
        rule %r/^\s*#\s*endif\b.*?(?<!\\)\n/m, Comment, :pop!
        rule %r/.*?\n/, Comment
      end
    end
  end
end
