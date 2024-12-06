# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    module TypescriptCommon
      def keywords
        @keywords ||= super + Set.new(%w(
          is namespace static private protected public
          implements readonly
        ))
      end

      def declarations
        @declarations ||= super + Set.new(%w(
          type abstract
        ))
      end

      def reserved
        @reserved ||= super + Set.new(%w(
          string any void number namespace module
          declare default interface keyof
        ))
      end

      def builtins
        @builtins ||= super + %w(
          Capitalize ConstructorParameters Exclude Extract InstanceType
          Lowercase NonNullable Omit OmitThisParameter Parameters
          Partial Pick Readonly Record Required
          ReturnType ThisParameterType ThisType Uncapitalize Uppercase
        )
      end

      def self.extended(base)
        base.prepend :root do
          rule %r/[?][.]/, base::Punctuation
          rule %r/[?]{2}/, base::Operator
        end

        base.prepend :statement do
          rule %r/(#{Javascript.id_regex})(\??)(\s*)(:)/ do
            groups base::Name::Label, base::Punctuation, base::Text, base::Punctuation
            push :expr_start
          end
        end
      end
    end
  end
end
