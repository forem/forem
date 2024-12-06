# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class VHDL < RegexLexer
      title "VHDL 2008"
      desc "Very High Speed Integrated Circuit Hardware Description Language"
      tag 'vhdl'

      filenames '*.vhd', '*.vhdl', '*.vho'

      mimetypes 'text/x-vhdl'
      def self.keywords
        @keywords ||= Set.new %w(
        access after alias all architecture array assert assume assume_guarantee attribute
        begin block body buffer bus case component configuration constant context cover
        default disconnect downto else elsif end entity exit fairness file for force function
        generate generic group guarded if impure in inertial inout is label library linkage
        literal loop map new next null of on open others out package parameter port postponed
        procedure process property protected pure range record register reject release report
        return select sequence severity shared signal strong subtype then to transport type
        unaffected units until use variable vmode vprop vunit wait when while with
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
        bit bit_vector boolean boolean_vector character integer integer_vector natural positive
        real real_vector severity_level signed std_logic std_logic_vector std_ulogic
        std_ulogic_vector string unsigned time time_vector
        )
      end

      def self.operator_words
        @operator_words ||= Set.new %w(
        abs and mod nand nor not or rem rol ror sla sll sra srl xnor xor
        )
      end

      id = /[a-zA-Z][a-zA-Z0-9_]*/

      state :whitespace do
        rule %r/\s+/, Text
        rule %r/\n/, Text
        # Find Comments (VHDL doesn't support multiline comments)
        rule %r/--.*$/, Comment::Single
      end

      state :statements do

        # Find Numbers
        rule %r/-?\d+/i, Num::Integer
        rule %r/-?\d+[.]\d+/i, Num::Float

        # Find Strings
        rule %r/[box]?"[^"]*"/i, Str::Single
        rule %r/'[^']?'/i, Str::Char

        # Find Attributes
        rule %r/'#{id}/i, Name::Attribute

        # Punctuations
        rule %r/[(),:;]/, Punctuation

        # Boolean and NULL
        rule %r/(?:true|false|null)\b/i, Name::Builtin

        rule id do |m|
          match = m[0].downcase   #convert to lower case
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.keywords_type.include? match
            token Keyword::Type
          elsif self.class.operator_words.include? match
            token Operator::Word
          else
            token Name
          end
        end

        rule(
        %r(=>|[*][*]|:=|\/=|>=|<=|<>|\?\?|\?=|\?\/=|\?>|\?<|\?>=|\?<=|<<|>>|[#&'*+-.\/:<=>\?@^]),
        Operator
        )

      end

      state :root do

        mixin :whitespace
        mixin :statements

      end

    end
  end
end
