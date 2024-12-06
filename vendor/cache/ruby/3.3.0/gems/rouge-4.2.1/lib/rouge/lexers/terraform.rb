# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'hcl.rb'

    class Terraform < Hcl
      title "Terraform"
      desc "Terraform HCL Interpolations"

      tag 'terraform'
      aliases 'tf'
      filenames '*.tf'

      def self.keywords
        @keywords ||= Set.new %w(
          terraform module provider variable resource data provisioner output
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(
          var local
        )
      end

      def self.reserved
        @reserved ||= Set.new %w()
      end

      def self.constants
        @constants ||= Set.new %w(true false null)
      end

      def self.builtins
        @builtins ||= %w()
      end

      state :strings do
        rule %r/\\./, Str::Escape
        rule %r/\$\{/ do
          token Keyword
          push :interpolation
        end
      end

      state :dq do
        rule %r/[^\\"\$]+/, Str::Double
        mixin :strings
        rule %r/"/, Str::Double, :pop!
      end

      state :sq do
        rule %r/[^\\'\$]+/, Str::Single
        mixin :strings
        rule %r/'/, Str::Single, :pop!
      end

      state :heredoc do
        rule %r/\n/, Str::Heredoc, :heredoc_nl
        rule %r/[^$\n]+/, Str::Heredoc
        rule %r/[$]/, Str::Heredoc
        mixin :strings
      end

      state :interpolation do
        rule %r/\}/ do
          token Keyword
          pop!
        end

        mixin :expression
      end

      state :regexps do
        rule %r/"\// do
          token Str::Delimiter
          goto :regexp_inner
        end
      end

      state :regexp_inner do
        rule %r/[^"\/\\]+/, Str::Regex
        rule %r/\\./, Str::Regex
        rule %r/\/"/, Str::Delimiter, :pop!
        rule %r/["\/]/, Str::Regex
      end

      id = /[$a-z_\-][a-z0-9_\-]*/io

      state :expression do
        mixin :regexps
        mixin :primitives
        rule %r/\s+/, Text

        rule %r(\+\+ | -- | ~ | && | \|\| | \\(?=\n) | << | >>>? | == | != )x, Operator
        rule %r([-<>+*%&|\^/!=?:]=?), Operator
        rule %r/[(\[,]/, Punctuation
        rule %r/[)\].]/, Punctuation

        rule id do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
          elsif self.class.reserved.include? m[0]
            token Keyword::Reserved
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          elsif self.class.builtins.include? m[0]
            token Name::Builtin
          else
            token Name::Other
          end
        end
      end
    end
  end
end
