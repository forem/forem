# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'jinja.rb'

    class Twig < Jinja
      title "Twig"
      desc "Twig template engine (twig.sensiolabs.org)"

      tag "twig"

      filenames '*.twig'

      mimetypes 'application/x-twig', 'text/html+twig'

      def self.keywords
        @keywords ||= %w(as do extends flush from import include use else starts
                         ends with without autoescape endautoescape block
                         endblock embed endembed filter endfilter for endfor
                         if endif macro endmacro sandbox endsandbox set endset
                         spaceless endspaceless)
      end

      def self.tests
        @tests ||= %w(constant defined divisibleby empty even iterable null odd
                      sameas)
      end

      def self.pseudo_keywords
        @pseudo_keywords ||= %w(true false none)
      end

      def self.word_operators
        @word_operators ||= %w(b-and b-or b-xor is in and or not)
      end
    end
  end
end
