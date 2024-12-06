# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class R < RegexLexer
      title "R"
      desc 'The R statistics language (r-project.org)'
      tag 'r'
      aliases 'r', 'R', 's', 'S'
      filenames '*.R', '*.r', '.Rhistory', '.Rprofile'
      mimetypes 'text/x-r-source', 'text/x-r', 'text/x-R'

      mimetypes 'text/x-r', 'application/x-r'

      KEYWORDS = %w(if else for while repeat in next break function)

      KEYWORD_CONSTANTS = %w(
        NULL Inf TRUE FALSE NaN NA
        NA_integer_ NA_real_ NA_complex_ NA_character_
      )

      BUILTIN_CONSTANTS = %w(LETTERS letters month.abb month.name pi T F)

      # These are all the functions in `base` that are implemented as a
      # `.Primitive`, minus those functions that are also keywords.
      PRIMITIVE_FUNCTIONS = %w(
        abs acos acosh all any anyNA Arg as.call as.character
        as.complex as.double as.environment as.integer as.logical
        as.null.default as.numeric as.raw asin asinh atan atanh attr
        attributes baseenv browser c call ceiling class Conj cos cosh
        cospi cummax cummin cumprod cumsum digamma dim dimnames
        emptyenv exp expression floor forceAndCall gamma gc.time
        globalenv Im interactive invisible is.array is.atomic is.call
        is.character is.complex is.double is.environment is.expression
        is.finite is.function is.infinite is.integer is.language
        is.list is.logical is.matrix is.na is.name is.nan is.null
        is.numeric is.object is.pairlist is.raw is.recursive is.single
        is.symbol lazyLoadDBfetch length lgamma list log max min
        missing Mod names nargs nzchar oldClass on.exit pos.to.env
        proc.time prod quote range Re rep retracemem return round
        seq_along seq_len seq.int sign signif sin sinh sinpi sqrt
        standardGeneric substitute sum switch tan tanh tanpi tracemem
        trigamma trunc unclass untracemem UseMethod xtfrm
      )

      def self.detect?(text)
        return true if text.shebang? 'Rscript'
      end

      state :root do
        rule %r/#'.*?$/, Comment::Doc
        rule %r/#.*?$/, Comment::Single
        rule %r/\s+/m, Text::Whitespace

        rule %r/`[^`]+?`/, Name
        rule %r/'(\\.|.)*?'/m, Str::Single
        rule %r/"(\\.|.)*?"/m, Str::Double

        rule %r/%[^%]*?%/, Operator

        rule %r/0[xX][a-fA-F0-9]+([pP][0-9]+)?[Li]?/, Num::Hex
        rule %r/[+-]?(\d+([.]\d+)?|[.]\d+)([eE][+-]?\d+)?[Li]?/, Num

        # Only recognize built-in functions when they are actually used as a
        # function call, i.e. followed by an opening parenthesis.
        # `Name::Builtin` would be more logical, but is usually not
        # highlighted specifically; thus use `Name::Function`.
        rule %r/\b(?<!.)(#{PRIMITIVE_FUNCTIONS.join('|')})(?=\()/, Name::Function

        rule %r/(?:(?:[[:alpha:]]|[.][._[:alpha:]])[._[:alnum:]]*)|[.]/ do |m|
          if KEYWORDS.include? m[0]
            token Keyword
          elsif KEYWORD_CONSTANTS.include? m[0]
            token Keyword::Constant
          elsif BUILTIN_CONSTANTS.include? m[0]
            token Name::Builtin
          else
            token Name
          end
        end

        rule %r/[\[\]{}();,]/, Punctuation

        rule %r([-<>?*+^/!=~$@:%&|]), Operator
      end
    end
  end
end
