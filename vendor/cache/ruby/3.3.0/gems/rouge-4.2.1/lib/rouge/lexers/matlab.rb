# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Matlab < RegexLexer
      title "MATLAB"
      desc "Matlab"
      tag 'matlab'
      aliases 'm'
      filenames '*.m'
      mimetypes 'text/x-matlab', 'application/x-matlab'

      def self.keywords
        @keywords = Set.new %w(
          arguments break case catch classdef continue else elseif end for
          function global if import methods otherwise parfor persistent
          properties return spmd switch try while
        )
      end

      # self-modifying method that loads the builtins file
      def self.builtins
        Kernel::load File.join(Lexers::BASE_DIR, 'matlab/keywords.rb')
        builtins
      end

      state :root do
        rule %r/\s+/m, Text # Whitespace
        rule %r([{]%.*?%[}])m, Comment::Multiline
        rule %r/%.*$/, Comment::Single
        rule %r/([.][.][.])(.*?)$/ do
          groups(Keyword, Comment)
        end

        rule %r/^(!)(.*?)(?=%|$)/ do |m|
          token Keyword, m[1]
          delegate Shell, m[2]
        end


        rule %r/[a-zA-Z][_a-zA-Z0-9]*/m do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.builtins.include? match
            token Name::Builtin
          else
            token Name
          end
        end

        rule %r{[(){};:,\/\\\]\[]}, Punctuation

        rule %r/~=|==|<<|>>|[-~+\/*%=<>&^|.@]/, Operator


        rule %r/(\d+\.\d*|\d*\.\d+)(e[+-]?[0-9]+)?/i, Num::Float
        rule %r/\d+e[+-]?[0-9]+/i, Num::Float
        rule %r/\d+L/, Num::Integer::Long
        rule %r/\d+/, Num::Integer

        rule %r/'(?=(.*'))/, Str::Single, :chararray
        rule %r/"(?=(.*"))/, Str::Double, :string
        rule %r/'/, Operator
      end

      state :chararray do
        rule %r/[^']+/, Str::Single
        rule %r/''/, Str::Escape
        rule %r/'/, Str::Single, :pop!
      end

      state :string do
        rule %r/[^"]+/, Str::Double
        rule %r/""/, Str::Escape
        rule %r/"/, Str::Double, :pop!
      end
    end
  end
end
