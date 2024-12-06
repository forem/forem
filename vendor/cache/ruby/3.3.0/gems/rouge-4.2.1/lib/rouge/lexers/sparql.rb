# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class SPARQL < RegexLexer
      title "SPARQL"
      desc "Semantic Query Language, for RDF data"
      tag 'sparql'
      filenames '*.rq'
      mimetypes 'application/sparql-query'

      def self.builtins
        @builtins = Set.new %w[
          ABS AVG BNODE BOUND CEIL COALESCE CONCAT CONTAINS COUNT DATATYPE DAY
          ENCODE_FOR_URI FLOOR GROUP_CONCAT HOURS IF IRI isBLANK isIRI
          isLITERAL isNUMERIC isURI LANG LANGMATCHES LCASE MAX MD5 MIN MINUTES
          MONTH NOW RAND REGEX REPLACE ROUND SAMETERM SAMPLE SECONDS SEPARATOR
          SHA1 SHA256 SHA384 SHA512 STR STRAFTER STRBEFORE STRDT STRENDS
          STRLANG STRLEN STRSTARTS STRUUID SUBSTR SUM TIMEZONE TZ UCASE URI
          UUID YEAR
        ]
      end

      def self.keywords
        @keywords = Set.new %w[
          ADD ALL AS ASC ASK BASE BIND BINDINGS BY CLEAR CONSTRUCT COPY CREATE
          DATA DEFAULT DELETE DESC DESCRIBE DISTINCT DROP EXISTS FILTER FROM
          GRAPH GROUP BY HAVING IN INSERT LIMIT LOAD MINUS MOVE NAMED NOT
          OFFSET OPTIONAL ORDER PREFIX SELECT REDUCED SERVICE SILENT TO UNDEF
          UNION USING VALUES WHERE WITH
        ]
      end

      state :root do
        rule %r(\s+)m, Text::Whitespace
        rule %r(#.*), Comment::Single

        rule %r("""), Str::Double, :string_double_literal
        rule %r("), Str::Double, :string_double
        rule %r('''), Str::Single, :string_single_literal
        rule %r('), Str::Single, :string_single

        rule %r([$?][[:word:]]+), Name::Variable
        rule %r(([[:word:]-]*)(:)([[:word:]-]+)?) do |m|
          token Name::Namespace, m[1]
          token Operator, m[2]
          token Str::Symbol, m[3]
        end
        rule %r(<[^>]*>), Name::Namespace
        rule %r(true|false)i, Keyword::Constant
        rule %r/a\b/, Keyword

        rule %r([A-Z][[:word:]]+\b)i do |m|
          if self.class.builtins.include? m[0].upcase
            token Name::Builtin
          elsif self.class.keywords.include? m[0].upcase
            token Keyword
          else
            token Error
          end
        end

        rule %r([+\-]?(?:\d+\.\d*|\.\d+)(?:[e][+\-]?[0-9]+)?)i, Num::Float
        rule %r([+\-]?\d+), Num::Integer
        rule %r([\]\[(){}.,;=]), Punctuation
        rule %r([/?*+=!<>]|&&|\|\||\^\^), Operator
      end

      state :string_double_common do
        mixin :string_escapes
        rule %r(\\), Str::Double
        rule %r([^"\\]+), Str::Double
      end

      state :string_double do
        rule %r(") do
          token Str::Double
          goto :string_end
        end
        mixin :string_double_common
      end

      state :string_double_literal do
        rule %r(""") do
          token Str::Double
          goto :string_end
        end
        rule %r("), Str::Double
        mixin :string_double_common
      end

      state :string_single_common do
        mixin :string_escapes
        rule %r(\\), Str::Single
        rule %r([^'\\]+), Str::Single
      end

      state :string_single do
        rule %r(') do
          token Str::Single
          goto :string_end
        end
        mixin :string_single_common
      end

      state :string_single_literal do
        rule %r(''') do
          token Str::Single
          goto :string_end
        end
        rule %r('), Str::Single
        mixin :string_single_common
      end

      state :string_escapes do
        rule %r(\\[tbnrf"'\\]), Str::Escape
        rule %r(\\u\h{4}), Str::Escape
        rule %r(\\U\h{8}), Str::Escape
      end

      state :string_end do
        rule %r((@)([a-zA-Z]+(?:-[a-zA-Z0-9]+)*)) do
          groups Operator, Name::Property
        end
        rule %r(\^\^), Operator
        rule(//) { pop! }
      end
    end
  end
end
