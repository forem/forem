# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Mathematica < RegexLexer
      title "Mathematica"
      desc "Wolfram Mathematica, the world's definitive system for modern technical computing."
      tag 'mathematica'
      aliases 'wl'
      filenames '*.m', '*.wl'
      mimetypes 'application/vnd.wolfram.mathematica.package', 'application/vnd.wolfram.wl'

      # Mathematica has various input forms for numbers. We need to handle numbers in bases, precision, accuracy,
      # and *^ scientific notation. All this works for integers and real numbers. Some examples
      # 1  1234567  1.1  .3  0.2  1*^10  2*^+10  3*^-10
      # 1`1  1``1  1.2`  1.2``1.234*^-10  1.2``1.234*^+10  1.2``1.234*^10
      # 2^^01001 10^^1.2``20.1234*^-10
      base = /(?:\d+)/
      number = /(?:\.\d+|\d+\.\d*|\d+)/
      number_base = /(?:\.\w+|\w+\.\w*|\w+)/
      precision = /`(`?#{number})?/

      operators = /[+\-*\/|,;.:@~=><&`'^?!_%]/
      braces = /[\[\](){}]/

      string = /"(\\\\|\\"|[^"])*"/

      # symbols and namespaced symbols. Note the special form \[Gamma] for named characters. These are also symbols.
      # Module With Block Integrate Table Plot
      # x32 $x x$ $Context` Context123`$x `Private`Context
      # \[Gamma] \[Alpha]x32 Context`\[Xi]
      identifier = /[a-zA-Z$][$a-zA-Z0-9]*/
      named_character = /\\\[#{identifier}\]/
      symbol = /(#{identifier}|#{named_character})+/
      context_symbol = /`?#{symbol}(`#{symbol})*`?/

      # Slots for pure functions.
      # Examples: # ## #1 ##3 #Test #"Test" #[Test] #["Test"]
      association_slot = /#(#{identifier}|\"#{identifier}\")/
      slot = /#{association_slot}|#[0-9]*/

      # Handling of message like symbol::usage or symbol::"argx"
      message = /::(#{identifier}|#{string})/

      # Highlighting of the special in and out markers that are prepended when you copy a cell
      in_out = /(In|Out)\[[0-9]+\]:?=/

      # Although Module, With and Block are normal built-in symbols, we give them a special treatment as they are
      # the most important expressions for defining local variables
      def self.keywords
        @keywords = Set.new %w(
          Module With Block
        )
      end

      # The list of built-in symbols comes from a wolfram server and is created automatically by rake
      def self.builtins
        Kernel::load File.join(Lexers::BASE_DIR, 'mathematica/keywords.rb')
        builtins
      end

      state :root do
        rule %r/\s+/, Text::Whitespace
        rule %r/\(\*/, Comment, :comment
        rule %r/#{base}\^\^#{number_base}#{precision}?(\*\^[+-]?\d+)?/, Num # a number with a base
        rule %r/(?:#{number}#{precision}?(?:\*\^[+-]?\d+)?)/, Num # all other numbers
        rule message, Name::Tag
        rule in_out, Generic::Prompt
        rule %r/#{context_symbol}/m do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Name::Builtin::Pseudo
          elsif self.class.builtins.include? match
            token Name::Builtin
          else
            token Name::Variable
          end
        end
        rule slot, Name::Function
        rule operators, Operator
        rule braces, Punctuation
        rule string, Str
      end

      # Allow for nested comments and special treatment of ::Section:: or :Author: markup
      state :comment do
        rule %r/\(\*/, Comment, :comment
        rule %r/\*\)/, Comment, :pop!
        rule %r/::#{identifier}::/, Comment::Preproc
        rule %r/[ ]:(#{identifier}|[^\S])+:[ ]/, Comment::Preproc
        rule %r/./, Comment
      end
    end
  end
end
