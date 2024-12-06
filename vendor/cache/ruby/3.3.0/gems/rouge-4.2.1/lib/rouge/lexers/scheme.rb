# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Scheme < RegexLexer
      title "Scheme"
      desc "The Scheme variant of Lisp"

      tag 'scheme'
      filenames '*.scm', '*.ss'
      mimetypes 'text/x-scheme', 'application/x-scheme'

      def self.keywords
        @keywords ||= Set.new %w(
          lambda define if else cond and or case let let* letrec begin
          do delay set! => quote quasiquote unquote unquote-splicing
          define-syntax let-syntax letrec-syntax syntax-rules
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          * + - / < <= = > >= abs acos angle append apply asin
          assoc assq assv atan boolean? caaaar caaadr caaar caadar
          caaddr caadr caar cadaar cadadr cadar caddar cadddr caddr
          cadr call-with-current-continuation call-with-input-file
          call-with-output-file call-with-values call/cc car cdaaar cdaadr
          cdaar cdadar cdaddr cdadr cdar cddaar cddadr cddar cdddar cddddr
          cdddr cddr cdr ceiling char->integer char-alphabetic? char-ci<=?
          char-ci<? char-ci=? char-ci>=? char-ci>? char-downcase
          char-lower-case? char-numeric? char-ready? char-upcase
          char-upper-case? char-whitespace? char<=? char<? char=? char>=?
          char>? char? close-input-port close-output-port complex? cons
          cos current-input-port current-output-port denominator
          display dynamic-wind eof-object? eq?  equal? eqv? eval
          even? exact->inexact exact? exp expt floor for-each force gcd
          imag-part inexact->exact inexact? input-port? integer->char
          integer? interaction-environment lcm length list list->string
          list->vector list-ref list-tail list?  load log magnitude
          make-polar make-rectangular make-string make-vector map
          max member memq memv min modulo negative? newline not
          null-environment null? number->string number? numerator odd?
          open-input-file open-output-file output-port? pair?  peek-char
          port? positive? procedure? quotient rational? rationalize
          read read-char real-part real?  remainder reverse round
          scheme-report-environment set-car! set-cdr! sin sqrt string
          string->list string->number string->symbol string-append
          string-ci<=?  string-ci<? string-ci=? string-ci>=? string-ci>?
          string-copy string-fill! string-length string-ref
          string-set! string<=? string<? string=? string>=?
          string>? string? substring symbol->string symbol?
          tan transcript-off transcript-on truncate values vector
          vector->list vector-fill! vector-length vector-ref
          vector-set! vector? with-input-from-file with-output-to-file
          write write-char zero?
        )
      end

      id = /[a-z0-9!$\%&*+,\/:<=>?@^_~|-]+/i

      state :root do
        # comments
        rule %r/;.*$/, Comment::Single
        rule %r/\s+/m, Text
        rule %r/-?\d+\.\d+/, Num::Float
        rule %r/-?\d+/, Num::Integer

        # Racket infinitites
        rule %r/[+-]inf[.][f0]/, Num

        rule %r/#b[01]+/, Num::Bin
        rule %r/#o[0-7]+/, Num::Oct
        rule %r/#d[0-9]+/, Num::Integer
        rule %r/#x[0-9a-f]+/i, Num::Hex
        rule %r/#[ei][\d.]+/, Num::Other

        rule %r/"(\\\\|\\"|[^"])*"/, Str
        rule %r/'#{id}/i, Str::Symbol
        rule %r/#\\([()\/'"._!\$%& ?=+-]{1}|[a-z0-9]+)/i,
          Str::Char
        rule %r/#t|#f/, Name::Constant
        rule %r/(?:'|#|`|,@|,|\.)/, Operator

        rule %r/(['#])(\s*)(\()/m do
          groups Str::Symbol, Text, Punctuation
        end

        rule %r/\(|\[/, Punctuation, :command
        rule %r/\)|\]/, Punctuation

        rule id, Name::Variable
      end

      state :command do
        rule id, Name::Function do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Function
          end

          pop!
        end

        rule(//) { pop! }
      end

    end
  end
end
