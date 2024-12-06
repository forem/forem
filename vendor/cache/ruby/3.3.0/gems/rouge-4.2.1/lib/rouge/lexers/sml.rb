# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class SML < RegexLexer
      title "SML"
      desc 'Standard ML'
      tag 'sml'
      aliases 'ml'
      filenames '*.sml', '*.sig', '*.fun'

      mimetypes 'text/x-standardml', 'application/x-standardml'

      def self.keywords
        @keywords ||= Set.new %w(
          abstype and andalso as case datatype do else end exception
          fn fun handle if in infix infixr let local nonfix of op open
          orelse raise rec then type val with withtype while
          eqtype functor include sharing sig signature struct structure
          where
        )
      end

      def self.symbolic_reserved
        @symbolic_reserved ||= Set.new %w(: | = => -> # :>)
      end

      id = /[\w']+/i
      symbol = %r([!%&$#/:<=>?@\\~`^|*+-]+)

      state :whitespace do
        rule %r/\s+/m, Text
        rule %r/[(][*]/, Comment, :comment
      end

      state :delimiters do
        rule %r/[(\[{]/, Punctuation, :main
        rule %r/[)\]}]/, Punctuation, :pop!

        rule %r/\b(let|if|local)\b(?!')/ do
          token Keyword::Reserved
          push; push
        end

        rule %r/\b(struct|sig|while)\b(?!')/ do
          token Keyword::Reserved
          push
        end

        rule %r/\b(do|else|end|in|then)\b(?!')/, Keyword::Reserved, :pop!
      end

      def token_for_id_with_dot(id)
        if self.class.keywords.include? id
          Error
        else
          Name::Namespace
        end
      end

      def token_for_final_id(id)
        if self.class.keywords.include? id or self.class.symbolic_reserved.include? id
          Error
        else
          Name
        end
      end

      def token_for_id(id)
        if self.class.keywords.include? id
          Keyword::Reserved
        elsif self.class.symbolic_reserved.include? id
          Punctuation
        else
          Name
        end
      end

      state :core do
        rule %r/[()\[\]{},;_]|[.][.][.]/, Punctuation
        rule %r/#"/, Str::Char, :char
        rule %r/"/, Str::Double, :string
        rule %r/~?0x[0-9a-fA-F]+/, Num::Hex
        rule %r/0wx[0-9a-fA-F]+/, Num::Hex
        rule %r/0w\d+/, Num::Integer
        rule %r/~?\d+([.]\d+)?[eE]~?\d+/, Num::Float
        rule %r/~?\d+[.]\d+/, Num::Float
        rule %r/~?\d+/, Num::Integer

        rule %r/#\s*[1-9][0-9]*/, Name::Label
        rule %r/#\s*#{id}/, Name::Label
        rule %r/#\s+#{symbol}/, Name::Label

        rule %r/\b(datatype|abstype)\b(?!')/, Keyword::Reserved, :dname
        rule(/(?=\bexception\b(?!'))/) { push :ename }
        rule %r/\b(functor|include|open|signature|structure)\b(?!')/,
          Keyword::Reserved, :sname
        rule %r/\b(type|eqtype)\b(?!')/, Keyword::Reserved, :tname

        rule %r/'#{id}/, Name::Decorator
        rule %r/(#{id})([.])/ do |m|
          groups(token_for_id_with_dot(m[1]), Punctuation)
          push :dotted
        end

        rule id do |m|
          token token_for_id(m[0])
        end

        rule symbol do |m|
          token token_for_id(m[0])
        end
      end

      state :dotted do
        rule %r/(#{id})([.])/ do |m|
          groups(token_for_id_with_dot(m[1]), Punctuation)
        end

        rule id do |m|
          token token_for_id(m[0])
          pop!
        end

        rule symbol do |m|
          token token_for_id(m[0])
          pop!
        end
      end

      state :root do
        rule %r/#!.*?\n/, Comment::Preproc
        rule(//) { push :main }
      end

      state :main do
        mixin :whitespace

        rule %r/\b(val|and)\b(?!')/, Keyword::Reserved, :vname
        rule %r/\b(fun)\b(?!')/ do
          token Keyword::Reserved
          goto :main_fun
          push :fname
        end

        mixin :delimiters
        mixin :core
      end

      state :main_fun do
        mixin :whitespace
        rule %r/\b(fun|and)\b(?!')/, Keyword::Reserved, :fname
        rule %r/\bval\b(?!')/ do
          token Keyword::Reserved
          goto :main
          push :vname
        end

        rule %r/[|]/, Punctuation, :fname
        rule %r/\b(case|handle)\b(?!')/ do
          token Keyword::Reserved
          goto :main
        end

        mixin :delimiters
        mixin :core
      end

      state :has_escapes do
        rule %r/\\[\\"abtnvfr]/, Str::Escape
        rule %r/\\\^[\x40-\x5e]/, Str::Escape
        rule %r/\\[0-9]{3}/, Str::Escape
        rule %r/\\u\h{4}/, Str::Escape
        rule %r/\\\s+\\/, Str::Interpol
      end

      state :string do
        rule %r/[^"\\]+/, Str::Double
        rule %r/"/, Str::Double, :pop!
        mixin :has_escapes
      end

      state :char do
        rule %r/[^"\\]+/, Str::Char
        rule %r/"/, Str::Char, :pop!
        mixin :has_escapes
      end

      state :breakout do
        rule %r/(?=\b(#{SML.keywords.to_a.join('|')})\b(?!'))/ do
          pop!
        end
      end

      state :sname do
        mixin :whitespace
        mixin :breakout
        rule id, Name::Namespace
        rule(//) { pop! }
      end

      state :has_annotations do
        rule %r/'[\w']*/, Name::Decorator
        rule %r/[(]/, Punctuation, :tyvarseq
      end

      state :fname do
        mixin :whitespace
        mixin :has_annotations

        rule id, Name::Function, :pop!
        rule symbol, Name::Function, :pop!
      end

      state :vname do
        mixin :whitespace
        mixin :has_annotations

        rule %r/(#{id})(\s*)(=(?!#{symbol}))/m do
          groups Name::Variable, Text, Punctuation
          pop!
        end

        rule %r/(#{symbol})(\s*)(=(?!#{symbol}))/m do
          groups Name::Variable, Text, Punctuation
        end

        rule id, Name::Variable, :pop!
        rule symbol, Name::Variable, :pop!

        rule(//) { pop! }
      end

      state :tname do
        mixin :whitespace
        mixin :breakout
        mixin :has_annotations

        rule %r/'[\w']*/, Name::Decorator
        rule %r/[(]/, Punctuation, :tyvarseq

        rule %r(=(?!#{symbol})) do
          token Punctuation
          goto :typbind
        end

        rule id, Keyword::Type
        rule symbol, Keyword::Type
      end

      state :typbind do
        mixin :whitespace

        rule %r/\b(and)\b(?!')/ do
          token Keyword::Reserved
          goto :tname
        end

        mixin :breakout
        mixin :core
      end

      state :dname do
        mixin :whitespace
        mixin :breakout
        mixin :has_annotations

        rule %r/(=)(\s*)(datatype)\b/ do
          groups Punctuation, Text, Keyword::Reserved
          pop!
        end

        rule %r(=(?!#{symbol})) do
          token Punctuation
          goto :datbind
          push :datcon
        end

        rule id, Keyword::Type
        rule symbol, Keyword::Type
      end

      state :datbind do
        mixin :whitespace
        rule %r/\b(and)\b(?!')/ do
          token Keyword::Reserved; goto :dname
        end
        rule %r/\b(withtype)\b(?!')/ do
          token Keyword::Reserved; goto :tname
        end
        rule %r/\bof\b(?!')/, Keyword::Reserved
        rule %r/([|])(\s*)(#{id})/ do
          groups(Punctuation, Text, Name::Class)
        end

        rule %r/([|])(\s+)(#{symbol})/ do
          groups(Punctuation, Text, Name::Class)
        end

        mixin :breakout
        mixin :core
      end

      state :ename do
        mixin :whitespace
        rule %r/(exception|and)(\s+)(#{id})/ do
          groups Keyword::Reserved, Text, Name::Class
        end

        rule %r/(exception|and)(\s*)(#{symbol})/ do
          groups Keyword::Reserved, Text, Name::Class
        end

        rule %r/\b(of)\b(?!')/, Keyword::Reserved
        mixin :breakout
        mixin :core
      end

      state :datcon do
        mixin :whitespace
        rule id, Name::Class, :pop!
        rule symbol, Name::Class, :pop!
      end

      state :tyvarseq do
        mixin :whitespace
        rule %r/'[\w']*/, Name::Decorator
        rule id, Name
        rule %r/,/, Punctuation
        rule %r/[)]/, Punctuation, :pop!
        rule symbol, Name
      end

      state :comment do
        rule %r/[^(*)]+/, Comment::Multiline
        rule %r/[(][*]/ do
          token Comment::Multiline; push
        end
        rule %r/[*][)]/, Comment::Multiline, :pop!
        rule %r/[(*)]/, Comment::Multiline
      end
    end
  end
end
