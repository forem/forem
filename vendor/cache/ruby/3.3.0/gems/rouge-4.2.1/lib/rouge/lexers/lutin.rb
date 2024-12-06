# -*- coding: utf-8 -*- #
# frozen_string_literal: true
#
# adapted from lustre.rf (adapted from ocaml.rb), hence some ocaml-ism migth remains
module Rouge
  module Lexers
    load_lexer 'lustre.rb'

    class Lutin < Lustre
      title "Lutin"
      desc 'The Lutin programming language (Verimag)'
      tag 'lutin'
      filenames '*.lut'
      mimetypes 'text/x-lutin'

      def self.keywords
        @keywords ||= Set.new %w(
          let in node extern system returns weak strong assert raise try catch
          trap do exist erun run type ref exception include false true 
        )
      end

      def self.word_operators
        @word_operators ||= Set.new %w(
           div and xor mod or not nor if then else pre) 
      end

      def self.primitives
        @primitives ||= Set.new %w(int real bool trace loop fby)
      end
    end
  end
end
