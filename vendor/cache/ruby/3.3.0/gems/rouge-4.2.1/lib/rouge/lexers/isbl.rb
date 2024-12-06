# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class ISBL < RegexLexer
      title "ISBL"
      desc "The ISBL programming language"
      tag 'isbl'
      filenames '*.isbl'

      def self.builtins
        Kernel::load File.join(Lexers::BASE_DIR, 'isbl/builtins.rb')
        self.builtins
      end

      def self.constants
        @constants ||= self.builtins["const"].merge(self.builtins["enum"]).collect!(&:downcase)
      end

      def self.interfaces
        @interfaces ||= self.builtins["interface"].collect!(&:downcase)
      end

      def self.globals
        @globals ||= self.builtins["global"].collect!(&:downcase)
      end

      def self.keywords
        @keywords = Set.new %w(
          and и else иначе endexcept endfinally endforeach конецвсе endif конецесли endwhile
          конецпока except exitfor finally foreach все if если in в not не or или try while пока
        )
      end

      state :whitespace do
        rule %r/\s+/m, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/[*].*?[*]/)m, Comment::Multiline
      end

      state :dotted do
        mixin :whitespace
        rule %r/[a-zа-яё_0-9]+/i do |m|
          name = m[0]
          if self.class.constants.include? name.downcase
            token Name::Builtin
          elsif in_state? :type
            token Keyword::Type
          else
            token Name
          end
          pop!
        end
      end

      state :type do
        mixin :whitespace
        rule %r/[a-zа-яё_0-9]+/i do |m|
          name = m[0]
          if self.class.interfaces.include? name.downcase
            token Keyword::Type
          else
            token Name
          end
          pop!
        end
        rule %r/[.]/, Punctuation, :dotted
        rule(//) { pop! }
      end

      state :root do
        mixin :whitespace
        rule %r/[:]/, Punctuation, :type
        rule %r/[.]/, Punctuation, :dotted
        rule %r/[\[\]();]/, Punctuation
        rule %r([&*+=<>/-]), Operator
        rule %r/\b[a-zа-яё_][a-zа-яё_0-9]*(?=[(])/i, Name::Function
        rule %r/[a-zа-яё_!][a-zа-яё_0-9]*/i do |m|
          name = m[0]
          if self.class.keywords.include? name.downcase
            token Keyword
          elsif self.class.constants.include? name.downcase
            token Name::Builtin
          elsif self.class.globals.include? name.downcase
            token Name::Variable::Global
          else
            token Name::Variable
          end
        end
        rule %r/\b(\d+(\.\d+)?)\b/, Literal::Number
        rule %r(["].*?["])m, Literal::String::Double
        rule %r(['].*?['])m, Literal::String::Single
      end
    end
  end
end
