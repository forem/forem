# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Swift < RegexLexer
      tag 'swift'
      filenames '*.swift'

      title "Swift"
      desc 'Multi paradigm, compiled programming language developed by Apple for iOS and OS X development. (developer.apple.com/swift)'

      id_head = /_|(?!\p{Mc})\p{Alpha}|[^\u0000-\uFFFF]/
      id_rest = /[\p{Alnum}_]|[^\u0000-\uFFFF]/
      id = /#{id_head}#{id_rest}*/

      keywords = Set.new %w(
        autoreleasepool await break case catch consume continue default defer discard do each else fallthrough guard if in for repeat return switch throw try where while

        as dynamicType is new super self Self Type

        associativity async didSet get infix inout isolated left mutating none nonmutating operator override postfix precedence precedencegroup prefix rethrows right set throws unowned weak willSet
      )

      declarations = Set.new %w(
        actor any associatedtype borrowing class consuming deinit distributed dynamic enum convenience extension fileprivate final func import indirect init internal lazy let macro nonisolated open optional package private protocol public required some static struct subscript typealias var
      )

      constants = Set.new %w(
        true false nil
      )

      start do
        push :bol
        @re_delim = "" # multi-line regex delimiter
      end

      # beginning of line
      state :bol do
        rule %r/#(?![#"\/]).*/, Comment::Preproc

        mixin :inline_whitespace

        rule(//) { pop! }
      end

      state :inline_whitespace do
        rule %r/\s+/m, Text
        mixin :has_comments
      end

      state :whitespace do
        rule %r/\n+/m, Text, :bol
        rule %r(\/\/.*?$), Comment::Single, :bol
        mixin :inline_whitespace
      end

      state :has_comments do
        rule %r(/[*]), Comment::Multiline, :nested_comment
      end

      state :nested_comment do
        mixin :has_comments
        rule %r([*]/), Comment::Multiline, :pop!
        rule %r([^*/]+)m, Comment::Multiline
        rule %r/./, Comment::Multiline
      end

      state :root do
        mixin :whitespace
        
        rule %r/\$(([1-9]\d*)?\d)/, Name::Variable
        rule %r/\$#{id}/, Name
        rule %r/~Copyable\b/, Keyword::Type

        rule %r{[()\[\]{}:;,?\\]}, Punctuation
        rule %r{(#*)/(?!\s).*(?<![\s\\])/\1}, Str::Regex
        rule %r([-/=+*%<>!&|^.~]+), Operator
        rule %r/@?"/, Str, :dq
        rule %r/'(\\.|.)'/, Str::Char
        rule %r/(\d+(?:_\d+)*\*|(?:\d+(?:_\d+)*)*\.\d+(?:_\d)*)(e[+-]?\d+(?:_\d)*)?/i, Num::Float
        rule %r/\d+e[+-]?[0-9]+/i, Num::Float
        rule %r/0o?[0-7]+(?:_[0-7]+)*/, Num::Oct
        rule %r/0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*((\.[0-9A-F]+(?:_[0-9A-F]+)*)?p[+-]?\d+)?/, Num::Hex
        rule %r/0b[01]+(?:_[01]+)*/, Num::Bin
        rule %r{[\d]+(?:_\d+)*}, Num::Integer

        rule %r/@#{id}/, Keyword::Declaration
        rule %r/##{id}/, Keyword

        rule %r/(private|internal)(\([ ]*)(\w+)([ ]*\))/ do |m|
          if m[3] == 'set'
            token Keyword::Declaration
          else
            groups Keyword::Declaration, Keyword::Declaration, Error, Keyword::Declaration
          end
        end

        rule %r/(unowned\([ ]*)(\w+)([ ]*\))/ do |m|
          if m[2] == 'safe' || m[2] == 'unsafe'
            token Keyword::Declaration
          else
            groups Keyword::Declaration, Error, Keyword::Declaration
          end
        end

        rule %r/(let|var)\b(\s*)(#{id})/ do
          groups Keyword, Text, Name::Variable
        end

        rule %r/(let|var)\b(\s*)([(])/ do
          groups Keyword, Text, Punctuation
          push :tuple
        end

        rule %r/(?!\b(if|while|for|private|internal|unowned|switch|case)\b)\b#{id}(?=(\?|!)?\s*[(])/ do |m|
          if m[0] =~ /^[[:upper:]]/
            token Keyword::Type
          else
            token Name::Function
          end
        end

        rule %r/as[?!]?(?=\s)/, Keyword
        rule %r/try[!]?(?=\s)/, Keyword

        rule %r/(#?(?!default)(?![[:upper:]])#{id})(\s*)(:)/ do
          groups Name::Variable, Text, Punctuation
        end

        rule id do |m|
          if keywords.include? m[0]
            token Keyword
          elsif declarations.include? m[0]
            token Keyword::Declaration
          elsif constants.include? m[0]
            token Keyword::Constant
          elsif m[0] =~ /^[[:upper:]]/
            token Keyword::Type
          else
            token Name
          end
        end

        rule %r/(`)(#{id})(`)/ do
          groups Punctuation, Name::Variable, Punctuation
        end

        rule %r{(#+)/\n} do |m|
          @re_delim = m[1]
          token Str::Regex
          push :re_multi
        end
      end

      state :tuple do
        rule %r/(#{id})/, Name::Variable
        rule %r/(`)(#{id})(`)/ do
            groups Punctuation, Name::Variable, Punctuation
        end
        rule %r/,/, Punctuation
        rule %r/[(]/, Punctuation, :push
        rule %r/[)]/, Punctuation, :pop!
        mixin :inline_whitespace
      end

      state :dq do
        rule %r/\\[\\0tnr'"]/, Str::Escape
        rule %r/\\[(]/, Str::Escape, :interp
        rule %r/\\u\{\h{1,8}\}/, Str::Escape
        rule %r/[^\\"]+/, Str
        rule %r/"""/, Str, :pop!
        rule %r/"/, Str, :pop!
      end

      state :interp do
        rule %r/[(]/, Punctuation, :interp_inner
        rule %r/[)]/, Str::Escape, :pop!
        mixin :root
      end

      state :interp_inner do
        rule %r/[(]/, Punctuation, :push
        rule %r/[)]/, Punctuation, :pop!
        mixin :root
      end

      state :re_multi do
        rule %r{^\s*/#+} do |m|
          token Str::Regex
          if m[0].end_with?("/#{@re_delim}")
            @re_delim = ""
            pop!
          end
        end

        rule %r/#.*/, Comment::Single
        rule %r/./m, Str::Regex
      end
    end
  end
end
