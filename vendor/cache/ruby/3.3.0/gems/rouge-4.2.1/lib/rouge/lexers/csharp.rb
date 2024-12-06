# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class CSharp < RegexLexer
      tag 'csharp'
      aliases 'c#', 'cs'
      filenames '*.cs'
      mimetypes 'text/x-csharp'

      title "C#"
      desc 'a multi-paradigm language targeting .NET'

      # TODO: support more of unicode
      id = /@?[_a-z]\w*/i

      #Reserved Identifiers
      #Contextual Keywords
      #LINQ Query Expressions
      keywords = %w(
        abstract as base break case catch checked const continue
        default delegate do else enum event explicit extern false
        finally fixed for foreach goto if implicit in interface
        internal is lock new null operator out override params private
        protected public readonly ref return sealed sizeof stackalloc
        static switch this throw true try typeof unchecked unsafe
        virtual void volatile while
        add alias async await get global partial remove set value where
        yield nameof notnull
        ascending by descending equals from group in init into join let
        on orderby select unmanaged when and not or with
      )

      keywords_type = %w(
        bool byte char decimal double dynamic float int long nint nuint
        object sbyte short string uint ulong ushort var
      )

      cpp_keywords = %w(
        if endif else elif define undef line error warning region
        endregion pragma nullable
      )

      state :whitespace do
        rule %r/\s+/m, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/[*].*?[*]/)m, Comment::Multiline
      end

      state :nest do
        rule %r/{/, Punctuation, :nest
        rule %r/}/, Punctuation, :pop!
        mixin :root
      end

      state :splice_string do
        rule %r/\\./, Str
        rule %r/{/, Punctuation, :nest
        rule %r/"|\n/, Str, :pop!
        rule %r/./, Str
      end

      state :splice_literal do
        rule %r/""/, Str
        rule %r/{/, Punctuation, :nest
        rule %r/"/, Str, :pop!
        rule %r/./, Str
      end

      state :root do
        mixin :whitespace

        rule %r/[$]\s*"/, Str, :splice_string
        rule %r/[$]@\s*"/, Str, :splice_literal

        rule %r/(<\[)\s*(#{id}:)?/, Keyword
        rule %r/\]>/, Keyword

        rule %r/[~!%^&*()+=|\[\]{}:;,.<>\/?-]/, Punctuation
        rule %r/@"(""|[^"])*"/m, Str
        rule %r/"(\\.|.)*?["\n]/, Str
        rule %r/'(\\.|.)'/, Str::Char
        rule %r/0b[_01]+[lu]?/i, Num
        rule %r/0x[_0-9a-f]+[lu]?/i, Num
        rule %r(
          [0-9](?:[_0-9]*[0-9])?
          ([.][0-9](?:[_0-9]*[0-9])?)? # decimal
          (e[+-]?[0-9](?:[_0-9]*[0-9])?)? # exponent
          [fldum]? # type
        )ix, Num
        rule %r/\b(?:class|record|struct|interface)\b/, Keyword, :class
        rule %r/\b(?:namespace|using)\b/, Keyword, :namespace
        rule %r/^#[ \t]*(#{cpp_keywords.join('|')})\b.*?\n/,
          Comment::Preproc
        rule %r/\b(#{keywords.join('|')})\b/, Keyword
        rule %r/\b(#{keywords_type.join('|')})\b/, Keyword::Type
        rule %r/#{id}(?=\s*[(])/, Name::Function
        rule id, Name
      end

      state :class do
        mixin :whitespace
        rule id, Name::Class, :pop!
      end

      state :namespace do
        mixin :whitespace
        rule %r/(?=[(])/, Text, :pop!
        rule %r/(#{id}|[.])+/, Name::Namespace, :pop!
      end

    end
  end
end
