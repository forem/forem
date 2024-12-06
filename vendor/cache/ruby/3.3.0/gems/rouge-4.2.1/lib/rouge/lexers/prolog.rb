# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Prolog < RegexLexer
      title "Prolog"
      desc "The Prolog programming language (http://en.wikipedia.org/wiki/Prolog)"
      tag 'prolog'
      aliases 'prolog'
      filenames '*.pro', '*.P', '*.prolog', '*.pl'
      mimetypes 'text/x-prolog'

      start { push :bol }

      state :bol do
        rule %r/#.*/, Comment::Single
        rule(//) { pop! }
      end

      state :basic do
        rule %r/\s+/, Text
        rule %r/%.*/, Comment::Single
        rule %r/\/\*/, Comment::Multiline, :nested_comment

        rule %r/[\[\](){}|.,;!]/, Punctuation
        rule %r/:-|-->/, Punctuation

        rule %r/"[^"]*"/, Str::Double

        rule %r/\d+\.\d+/, Num::Float
        rule %r/\d+/, Num
      end

      state :atoms do
        rule %r/[[:lower:]]([[:word:]])*/, Str::Symbol
        rule %r/'[^']*'/, Str::Symbol
      end

      state :operators do
        rule %r/(<|>|=<|>=|==|=:=|=|\/|\/\/|\*|\+|-)(?=\s|[a-zA-Z0-9\[])/,
          Operator
        rule %r/is/, Operator
        rule %r/(mod|div|not)/, Operator
        rule %r/[#&*+-.\/:<=>?@^~]+/, Operator
      end

      state :variables do
        rule %r/[A-Z]+\w*/, Name::Variable
        rule %r/_[[:word:]]*/, Name::Variable
      end

      state :root do
        mixin :basic
        mixin :atoms
        mixin :variables
        mixin :operators
      end

      state :nested_comment do
        rule %r(/\*), Comment::Multiline, :push
        rule %r/\s*\*[^*\/]+/, Comment::Multiline
        rule %r(\*/), Comment::Multiline, :pop!
      end
    end
  end
end
