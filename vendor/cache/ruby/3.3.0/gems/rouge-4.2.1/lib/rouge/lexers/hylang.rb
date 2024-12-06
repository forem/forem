# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class HyLang < RegexLexer
      title "HyLang"
      desc "The HyLang programming language (hylang.org)"

      tag 'hylang'
      aliases 'hy'

      filenames '*.hy'

      mimetypes 'text/x-hy', 'application/x-hy'

      def self.keywords
        @keywords ||= Set.new %w(
          False None True and as assert break class continue def
          del elif else except finally for from global if import
          in is lambda nonlocal not or pass raise return try
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          != % %= & &= * ** **= *= *map
          + += , - -= -> ->> . / //
          //= /= < << <<= <= = > >= >>
          >>= @ @= ^ ^= accumulate apply as-> assoc butlast
          calling-module-name car cdr chain coll? combinations comp complement compress cond
          cons cons? constantly count cut cycle dec defclass defmacro defmacro!
          defmacro/g! defmain defn defreader dict-comp disassemble dispatch-reader-macro distinct do doto
          drop drop-last drop-while empty? eval eval-and-compile eval-when-compile even? every? filter
          first flatten float? fn for* fraction genexpr gensym get group-by
          identity if* if-not if-python2 inc input instance? integer integer-char? integer?
          interleave interpose islice iterable? iterate iterator? juxt keyword keyword? last
          let lif lif-not list* list-comp macro-error macroexpand macroexpand-1 map merge-with
          multicombinations name neg? none? not-in not? nth numeric? odd? partition
          permutations pos? product quasiquote quote range read read-str reduce remove
          repeat repeatedly require rest second set-comp setv some string string?
          symbol? take take-nth take-while tee unless unquote unquote-splicing when with*
          with-decorator with-gensyms xor yield-from zero? zip zip-longest | |= ~
        )
      end

      identifier = %r([\w!$%*+,<=>?/.-]+)
      keyword = %r([\w!\#$%*+,<=>?/.-]+)

      def name_token(name)
        return Keyword if self.class.keywords.include?(name)
        return Name::Builtin if self.class.builtins.include?(name)
        nil
      end

      state :root do
        rule %r/;.*?$/, Comment::Single
        rule %r/\s+/m, Text::Whitespace

        rule %r/-?\d+\.\d+/, Num::Float
        rule %r/-?\d+/, Num::Integer
        rule %r/0x-?[0-9a-fA-F]+/, Num::Hex

        rule %r/"(\\.|[^"])*"/, Str
        rule %r/'#{keyword}/, Str::Symbol
        rule %r/::?#{keyword}/, Name::Constant
        rule %r/\\(.|[a-z]+)/i, Str::Char


        rule %r/~@|[`\'#^~&@]/, Operator

        rule %r/(\()(\s*)(#{identifier})/m do |m|
          token Punctuation, m[1]
          token Text::Whitespace, m[2]
          token(name_token(m[3]) || Name::Function, m[3])
        end

        rule identifier do |m|
          token name_token(m[0]) || Name
        end

        # vectors
        rule %r/[\[\]]/, Punctuation

        # maps
        rule %r/[{}]/, Punctuation

        # parentheses
        rule %r/[()]/, Punctuation
      end
    end
  end
end
