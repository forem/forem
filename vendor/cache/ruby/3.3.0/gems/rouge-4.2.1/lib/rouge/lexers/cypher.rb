# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Cypher < RegexLexer
      tag 'cypher'
      aliases 'cypher'
      filenames '*.cypher'
      mimetypes 'application/x-cypher-query'

      title "Cypher"
      desc 'The Cypher query language (neo4j.com/docs/cypher-manual)'

      def self.functions
        @functions ||= Set.new %w(
          ABS ACOS ALLSHORTESTPATHS ASIN ATAN ATAN2 AVG CEIL COALESCE COLLECT
          COS COT COUNT DATE DEGREES E ENDNODE EXP EXTRACT FILTER FLOOR
          HAVERSIN HEAD ID KEYS LABELS LAST LEFT LENGTH LOG LOG10 LOWER LTRIM
          MAX MIN NODE NODES PERCENTILECONT PERCENTILEDISC PI RADIANS RAND
          RANGE REDUCE REL RELATIONSHIP RELATIONSHIPS REPLACE REVERSE RIGHT
          ROUND RTRIM SHORTESTPATH SIGN SIN SIZE SPLIT SQRT STARTNODE STDEV
          STDEVP STR SUBSTRING SUM TAIL TAN TIMESTAMP TOFLOAT TOINT TOINTEGER
          TOSTRING TRIM TYPE UPPER
        )
      end

      def self.predicates
        @predicates ||= Set.new %w(
          ALL AND ANY CONTAINS EXISTS HAS IN NONE NOT OR SINGLE XOR
        )
      end

      def self.keywords
        @keywords ||= Set.new %w(
          AS ASC ASCENDING ASSERT BY CASE COMMIT CONSTRAINT CREATE CSV CYPHER
          DELETE DESC DESCENDING DETACH DISTINCT DROP ELSE END ENDS EXPLAIN
          FALSE FIELDTERMINATOR FOREACH FROM HEADERS IN INDEX IS JOIN LIMIT
          LOAD MATCH MERGE NULL ON OPTIONAL ORDER PERIODIC PROFILE REMOVE
          RETURN SCAN SET SKIP START STARTS THEN TRUE UNION UNIQUE UNWIND USING
          WHEN WHERE WITH CALL YIELD
        )
      end

      state :root do
        rule %r/[\s]+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/\*), Comment::Multiline, :multiline_comments

        rule %r([*+\-<>=&|~%^]), Operator
        rule %r/[{}),;\[\]]/, Str::Symbol

        # literal number
        rule %r/(\w+)(:)(\s*)(-?[._\d]+)/ do
          groups Name::Label, Str::Delimiter, Text::Whitespace, Num
        end

        # function-like
        # - "name("
        # - "name  ("
        # - "name ("
        rule %r/(\w+)(\s*)(\()/ do |m|
          name = m[1].upcase
          if self.class.functions.include? name
            groups Name::Function, Text::Whitespace, Str::Symbol
          elsif self.class.keywords.include? name
            groups Keyword, Text::Whitespace, Str::Symbol
          else
            groups Name, Text::Whitespace, Str::Symbol
          end
        end

        rule %r/:\w+/, Name::Class

        # number range
        rule %r/(-?\d+)(\.\.)(-?\d+)/ do
          groups Num, Operator, Num
        end

        # numbers
        rule %r/(\d+\.\d*|\d*\.\d+)(e[+-]?\d+)?/i, Num::Float
        rule %r/\d+e[+-]?\d+/i, Num::Float
        rule %r/0[0-7]+/, Num::Oct
        rule %r/0x[a-f0-9]+/i, Num::Hex
        rule %r/\d+/, Num::Integer

        rule %r([.\w]+:), Name::Property

        # remaining "("
        rule %r/\(/, Str::Symbol

        rule %r/[.\w$]+/ do |m|
          match = m[0].upcase
          if self.class.predicates.include? match
            token Operator::Word
          elsif self.class.keywords.include? match
            token Keyword
          else
            token Name
          end
        end

        rule %r/"(\\\\|\\"|[^"])*"/, Str::Double
        rule %r/'(\\\\|\\'|[^'])*'/, Str::Single
        rule %r/`(\\\\|\\`|[^`])*`/, Str::Backtick
      end

      state :multiline_comments do
        rule %r(/[*]), Comment::Multiline, :multiline_comments
        rule %r([*]/), Comment::Multiline, :pop!
        rule %r([^/*]+), Comment::Multiline
        rule %r([/*]), Comment::Multiline
      end
    end
  end
end
