# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Kotlin < RegexLexer
      # https://kotlinlang.org/docs/reference/grammar.html

      title "Kotlin"
      desc "Kotlin Programming Language (http://kotlinlang.org)"

      tag 'kotlin'
      filenames '*.kt', '*.kts'
      mimetypes 'text/x-kotlin'

      keywords = %w(
        abstract annotation as break by catch class companion const
        constructor continue crossinline do dynamic else enum
        external false final finally for fun get if import in infix
        inline inner interface internal is lateinit noinline null
        object open operator out override package private protected
        public reified return sealed set super suspend tailrec this
        throw true try typealias typeof val var vararg when where
        while yield
      )

      name_chars = %r'[-\p{Lu}\p{Ll}\p{Lt}\p{Lm}\p{Nl}\p{Nd}\p{Pc}\p{Cf}\p{Mn}\p{Mc}]*'

      class_name = %r'`?[\p{Lu}]#{name_chars}`?'
      name = %r'`?[_\p{Lu}\p{Ll}\p{Lt}\p{Lm}\p{Nl}]#{name_chars}`?'

      state :root do
        rule %r'\b(companion)(\s+)(object)\b' do
          groups Keyword, Text, Keyword
        end
        rule %r'\b(class|data\s+class|interface|object)(\s+)' do
          groups Keyword::Declaration, Text
          push :class
        end
        rule %r'\b(fun)(\s+)' do
          groups Keyword, Text
          push :function
        end
        rule %r'\b(package|import)(\s+)' do
          groups Keyword, Text
          push :package
        end
        rule %r'\b(val|var)(\s+)(\()' do
          groups Keyword::Declaration, Text, Punctuation
          push :destructure
        end
        rule %r'\b(val|var)(\s+)' do
          groups Keyword::Declaration, Text
          push :property
        end
        rule %r'(return|continue|break|this|super)(@#{name})?\b' do
          groups Keyword, Name::Decorator
        end
        rule %r'\bfun\b', Keyword
        rule %r'\b(?:#{keywords.join('|')})\b', Keyword
        rule %r'^\s*\[.*?\]', Name::Attribute
        rule %r'[^\S\n]+', Text
        rule %r'\\\n', Text # line continuation
        rule %r'//.*?$', Comment::Single
        rule %r'/[*].*[*]/', Comment::Multiline # single line block comment
        rule %r'/[*].*', Comment::Multiline, :comment # multiline block comment
        rule %r'\n', Text
        rule %r'(::)(class)' do
          groups Operator, Keyword
        end
        rule %r'::|!!|\?[:.]', Operator
        rule %r"(\.\.)", Operator
        # Number literals
        decDigits = %r"([0-9][0-9_]*[0-9])|[0-9]"
        exponent = %r"[eE][+-]?(#{decDigits})"
        double = %r"((#{decDigits})?\.#{decDigits}(#{exponent})?)|(#{decDigits}#{exponent})"
        rule %r"(#{double}[fF]?)|(#{decDigits}[fF])", Num::Float
        rule %r"0[bB]([01][01_]*[01]|[01])[uU]?L?", Num::Bin
        rule %r"0[xX]([0-9a-fA-F][0-9a-fA-F_]*[0-9a-fA-F]|[0-9a-fA-F])[uU]?L?", Num::Hex
        rule %r"(([1-9][0-9_]*[0-9])|[0-9])[uU]?L?", Num::Integer
        rule %r'[~!%^&*()+=|\[\]:;,.<>/?-]', Punctuation
        rule %r'[{}]', Punctuation
        rule %r'@"(""|[^"])*"'m, Str
        rule %r'""".*?"""'m, Str
        rule %r'"(\\\\|\\"|[^"\n])*["\n]'m, Str
        rule %r"'\\.'|'[^\\]'", Str::Char
        rule %r'(@#{class_name})', Name::Decorator
        rule %r'(#{class_name})(<)' do
          groups Name::Class, Punctuation
          push :generic_parameters
        end
        rule class_name, Name::Class
        rule %r'(#{name})(?=\s*[({])', Name::Function
        rule %r'(#{name})@', Name::Decorator # label
        rule name, Name
      end

      state :package do
        rule %r'\S+', Name::Namespace, :pop!
      end

      state :class do
        rule class_name, Name::Class, :pop!
      end

      state :function do
        rule %r'(<)', Punctuation, :generic_parameters
        rule %r'(\s+)', Text
        rule %r'(#{class_name})(\.)' do
          groups Name::Class, Punctuation
        end
        rule name, Name::Function, :pop!
      end

      state :generic_parameters do
        rule class_name, Name::Class
        rule %r'(<)', Punctuation, :generic_parameters
        rule %r'(reified|out|in)', Keyword
        rule %r'([,:.?])', Punctuation
        rule %r'(\s+)', Text
        rule %r'(>)', Punctuation, :pop!
      end

      state :property do
        rule %r'(<)', Punctuation, :generic_parameters
        rule %r'(\s+)', Text
        rule name, Name::Property, :pop!
      end

      state :destructure do
        rule %r'(,)', Punctuation
        rule %r'(\))', Punctuation, :pop!
        rule %r'(\s+)', Text
        rule name, Name::Property
      end

      state :comment do
        rule %r'/[*]', Comment::Multiline, :comment
        rule %r'[*]/', Comment::Multiline, :pop!
        rule %r'[^/*]+', Comment::Multiline
        rule %r'[/*]', Comment::Multiline
      end
    end
  end
end
