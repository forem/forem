# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Pascal < RegexLexer
      tag 'pascal'
      title "Pascal"
      desc 'a procedural programming language commonly used as a teaching language.'
      filenames '*.pas', '*.lpr', '*.pp'

      mimetypes 'text/x-pascal'

      id = /@?[_a-z]\w*/i

      keywords = %w(
        absolute abstract all and and_then array as asm assembler attribute
        begin bindable case class const constructor delay destructor div do
        downto else end except exit export exports external far file finalization
        finally for forward function goto if implementation import in inc index
        inherited initialization inline interface interrupt is label library
        message mod module near nil not object of on only operator or or_else
        otherwise out overload override packed pascal pow private procedure program
        property protected public published qualified raise read record register
        repeat resident resourcestring restricted safecall segment set shl shr
        stdcall stored string then threadvar to try type unit until uses value var
        view virtual while with write writeln xor
      )

      keywords_type = %w(
        ansichar ansistring bool boolean byte bytebool cardinal char comp currency
        double dword extended int64 integer iunknown longbool longint longword pansichar
        pansistring pbool pboolean pbyte pbytearray pcardinal pchar pcomp pcurrency
        pdate pdatetime pdouble pdword pextended phandle pint64 pinteger plongint plongword
        pointer ppointer pshortint pshortstring psingle psmallint pstring pvariant pwidechar
        pwidestring pword pwordarray pwordbool real real48 shortint shortstring single
        smallint string tclass tdate tdatetime textfile thandle tobject ttime variant
        widechar widestring word wordbool
      )

      state :whitespace do
        # Spaces
        rule %r/\s+/m, Text
        # // Comments
        rule %r((//).*$\n?), Comment::Single
        # -- Comments
        rule %r((--).*$\n?), Comment::Single
        # (* Comments *)
        rule %r(\(\*.*?\*\))m, Comment::Multiline
        # { Comments }
        rule %r(\{.*?\})m, Comment::Multiline
      end

      state :root do
        mixin :whitespace

        rule %r{((0(x|X)[0-9a-fA-F]*)|(([0-9]+\.?[0-9]*)|(\.[0-9]+))((e|E)(\+|-)?[0-9]+)?)(L|l|UL|ul|u|U|F|f|ll|LL|ull|ULL)?}, Num
        rule %r/\$[0-9A-Fa-f]+/, Num::Hex
        rule %r{[~!@#\$%\^&\*\(\)\+`\-={}\[\]:;<>\?,\.\/\|\\]}, Punctuation
        rule %r{'([^']|'')*'}, Str
        rule %r/(true|false|nil)\b/i, Name::Builtin
        rule %r/\b(#{keywords.join('|')})\b/i, Keyword
        rule %r/\b(#{keywords_type.join('|')})\b/i, Keyword::Type
        rule id, Name
      end
    end
  end
end
