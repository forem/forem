# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Magik < RegexLexer
      title "Magik"
      desc "Smallworld Magik"
      tag 'magik'
      filenames '*.magik'
      mimetypes 'text/x-magik', 'application/x-magik'

      def self.keywords
        @keywords ||= %w(
           _package
           _pragma
           _block _endblock
           _handling _default
           _protect _protection _endprotect
           _try _with _when _endtry
           _catch _endcatch
           _throw
           _lock _endlock
           _if _then _elif _else _endif
           _for _over _while _loop _finally _endloop _loopbody _continue _leave
           _return
           _class
           _local _constant _recursive _global _dynamic _import
           _private _iter _abstract _method _endmethod
           _proc _endproc
           _gather _scatter _allresults _optional
           _thisthread _self _clone _super
           _primitive
           _unset _true _false _maybe
           _is _isnt _not _and _or _xor _cf _andif _orif
           _div _mod
        )
      end

      def self.string_double
        @string_double ||= /"[^"\n]*?"/
      end
      def self.string_single
        @string_single ||= /'[^'\n]*?'/
      end

      def self.digits
        @digits ||= /[0-9]+/
      end
      def self.radix
        @radix ||= /r[0-9a-z]/i
      end
      def self.exponent
        @exponent ||= /(e|&)[+-]?#{Magik.digits}/i
      end
      def self.decimal
        @decimal ||= /\.#{Magik.digits}/
      end
      def self.number
        @number = /#{Magik.digits}(#{Magik.radix}|#{Magik.exponent}|#{Magik.decimal})*/
      end

      def self.character
        @character ||= /%u[0-9a-z]{4}|%[^\s]+/i
      end

      def self.simple_identifier
        @simple_identifier ||= /(?>(?:[a-z0-9_!?]|\\.)+)/i
      end
      def self.piped_identifier
        @piped_identifier ||= /\|[^\|\n]*\|/
      end
      def self.identifier
        @identifier ||= /(?:#{Magik.simple_identifier}|#{Magik.piped_identifier})+/i
      end
      def self.package_identifier
        @package_identifier ||= /#{Magik.identifier}:#{Magik.identifier}/
      end
      def self.symbol
        @symbol ||= /:#{Magik.identifier}/i
      end
      def self.global_ref
        @global_ref ||= /@[\s]*#{Magik.identifier}:#{Magik.identifier}/
      end
      def self.label
        @label = /@[\s]*#{Magik.identifier}/
      end

      state :root do
        rule %r/##(.*)?/, Comment::Doc
        rule %r/#(.*)?/, Comment::Single

        rule %r/(_method)(\s+)/ do
          groups Keyword, Text::Whitespace
          push :method_name
        end

        rule %r/(?:#{Magik.keywords.join('|')})\b/, Keyword

        rule Magik.string_double, Literal::String
        rule Magik.string_single, Literal::String
        rule Magik.symbol, Str::Symbol
        rule Magik.global_ref, Name::Label
        rule Magik.label, Name::Label
        rule Magik.character, Literal::String::Char
        rule Magik.number, Literal::Number
        rule Magik.package_identifier, Name
        rule Magik.identifier, Name

        rule %r/[\[\]{}()\.,;]/, Punctuation
        rule %r/\$/, Punctuation
        rule %r/(<<|^<<)/, Operator
        rule %r/(>>)/, Operator
        rule %r/[-~+\/*%=&^<>]|!=/, Operator

        rule %r/[\s]+/, Text::Whitespace
      end

      state :method_name do
        rule %r/(#{Magik.identifier})(\.)(#{Magik.identifier})/ do
          groups Name::Class, Punctuation, Name::Function
          pop!
        end
      end
    end
  end
end
