# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# NOTE: This is for Lean 3 (community fork).
module Rouge
  module Lexers
    class Lean < RegexLexer
      title 'Lean'
      desc 'The Lean programming language (leanprover.github.io)'
      tag 'lean'
      aliases 'lean'
      filenames '*.lean'

      def self.keywords
        @keywords ||= Set.new %w(
          abbreviation
          add_rewrite
          alias
          assume
          axiom
          begin
          by
          calc
          calc_refl
          calc_subst
          calc_trans
          #check
          coercion
          conjecture
          constant
          constants
          context
          corollary
          def
          definition
          end
          #eval
          example
          export
          expose
          exposing
          exit
          extends
          from
          fun
          have
          help
          hiding
          hott
          hypothesis
          import
          include
          including
          inductive
          infix
          infixl
          infixr
          inline
          instance
          irreducible
          lemma
          match
          namespace
          notation
          opaque
          opaque_hint
          open
          options
          parameter
          parameters
          postfix
          precedence
          prefix
          #print
          private
          protected
          #reduce
          reducible
          renaming
          repeat
          section
          set_option
          show
          tactic_hint
          theorem
          universe
          universes
          using
          variable
          variables
          with
        )
      end

      def self.types
        @types ||= %w(
          Sort
          Prop
          Type
        )
      end

      def self.operators
        @operators ||= %w(
          != # & && \* \+ - / @ ! ` -\. ->
          \. \.\. \.\.\. :: :> ; ;; <
          <- = == > _ \| \|\| ~ => <= >=
          /\ \/ ∀ Π λ ↔ ∧ ∨ ≠ ≤ ≥ ⊎
          ¬ ⁻¹ ⬝ ▸ → ∃ ℕ ℤ ≈ × ⌞ ⌟ ≡ ⟨ ⟩
        )
      end

      state :root do
        # comments starting after some space
        rule %r/\s*--+\s+.*?$/, Comment::Doc

        rule %r/"/, Str, :string
        rule %r/\d+/, Num::Integer

        # special commands or keywords
        rule(/#?\w+/) do |m|
          match = m[0]
          if self.class.keywords.include?(match)
            token Keyword
          elsif self.class.types.include?(match)
            token Keyword::Type
          else
            token Name
          end
        end

        # special unicode keywords
        rule %r/[λ]/, Keyword

        # ----------------
        # operators rules
        # ----------------

        rule %r/\:=?/, Text
        rule %r/\.[0-9]*/, Operator

        rule %r(#{Lean.operators.join('|')}), Operator

        # unmatched symbols
        rule %r/[\s\(\),\[\]αβ‹›]+/, Text

        # show missing matches
        rule %r/./, Error

      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\/, Str::Escape, :escape
        rule %r/[^\\"]+/, Str
      end

      state :escape do
        rule %r/[nrt"'\\]/, Str::Escape, :pop!
        rule %r/x[\da-f]+/i, Str::Escape, :pop!
      end
    end
  end
end
