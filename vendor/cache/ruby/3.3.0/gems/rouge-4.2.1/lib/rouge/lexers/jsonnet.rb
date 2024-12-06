# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Jsonnet < RegexLexer
      title 'Jsonnet'
      desc 'An elegant, formally-specified config language for JSON'
      tag 'jsonnet'
      filenames '*.jsonnet', '*.libsonnet'
      mimetypes 'text/x-jsonnet'

      def self.keywords
        @keywords ||= Set.new %w(
          self super local for in if then else import importstr error
          tailstrict assert
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(
          function
        )
      end

      def self.constants
        @constants ||= Set.new %w(
          null true false
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          acos
          asin
          atan
          ceil
          char
          codepoint
          cos
          exp
          exponent
          filter
          floor
          force
          length
          log
          makeArray
          mantissa
          objectFields
          objectHas
          pow
          sin
          sqrt
          tan
          thisFile
          type
          abs
          assertEqual
          escapeStringBash
          escapeStringDollars
          escapeStringJson
          escapeStringPython
          filterMap
          flattenArrays
          foldl
          foldr
          format
          join
          lines
          manifestIni
          manifestPython
          manifestPythonVars
          map
          max
          min
          mod
          range
          set
          setDiff
          setInter
          setMember
          setUnion
          sort
          split
          stringChars
          substr
          toString
          uniq
        )
      end

      identifier = /[a-zA-Z_][a-zA-Z0-9_]*/

      state :root do
        rule %r/\s+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(#.*?$), Comment::Single
        rule %r(/\*.*?\*/)m, Comment::Multiline

        rule %r/-?(?:0|[1-9]\d*)\.\d+(?:e[+-]\d+)?/i, Num::Float
        rule %r/-?(?:0|[1-9]\d*)(?:e[+-]\d+)?/i, Num::Integer

        rule %r/[{}:\.,;+\[\]=%\(\)]/, Punctuation

        rule %r/"/, Str, :string_double
        rule %r/'/, Str, :string_single
        rule %r/\|\|\|/, Str, :string_block

        rule %r/\$/, Keyword

        rule identifier do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end
        end
      end

      state :string do
        rule %r/\\([\\\/bfnrt]|(u[0-9a-fA-F]{4}))/, Str::Escape
        rule %r/\\./, Str::Escape
      end

      state :string_double do
        mixin :string
        rule %r/\\"/, Str::Escape
        rule %r/"/, Str, :pop!
        rule %r/[^\\"]+/, Str
      end

      state :string_single do
        mixin :string
        rule %r/'/, Str, :pop!
        rule %r/[^\\']+/, Str
      end

      state :string_block do
        mixin :string
        rule %r/[|][|][|]/, Str, :pop!
        rule %r/[^|\\]+/, Str
        rule %r/[|]/, Str
      end
    end
  end
end
