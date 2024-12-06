# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
    module Lexers
        class Rego < RegexLexer
            title "Rego"
            desc "The Rego open-policy-agent (OPA) policy language (openpolicyagent.org)"
            tag 'rego'
            filenames '*.rego'

            def self.constants
              @constants ||= Set.new %w(
                true false null
              )
            end

            def self.operators
              @operators ||= Set.new %w(
                as default else import not package some with
              )
            end

            state :basic do
              rule %r/\s+/, Text
              rule %r/#.*/, Comment::Single

              rule %r/[\[\](){}|.,;!]/, Punctuation

              rule %r/"[^"]*"/, Str::Double

              rule %r/-?\d+\.\d+([eE][+-]?\d+)?/, Num::Float
              rule %r/-?\d+([eE][+-]?\d+)?/, Num

              rule %r/\\u[0-9a-fA-F]{4}/, Num::Hex
              rule %r/\\["\/bfnrt]/, Str::Escape
            end

            state :operators do
              rule %r/(=|!=|>=|<=|>|<|\+|-|\*|%|\/|\||&|:=)/, Operator
              rule %r/[\/:?@^~]+/, Operator
            end

            state :root do
              mixin :basic
              mixin :operators

              rule %r/[[:word:]]+/ do |m|
                if self.class.constants.include? m[0]
                  token Keyword::Constant
                elsif self.class.operators.include? m[0]
                  token Operator::Word
                else
                  token Name
                end
              end
            end
        end
    end
end
