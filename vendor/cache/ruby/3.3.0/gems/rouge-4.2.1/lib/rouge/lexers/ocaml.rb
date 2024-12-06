# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'ocaml/common.rb'

    class OCaml < OCamlCommon
      title "OCaml"
      desc 'Objective Caml (ocaml.org)'
      tag 'ocaml'
      filenames '*.ml', '*.mli', '*.mll', '*.mly'
      mimetypes 'text/x-ocaml'

      def self.keywords
        @keywords ||= super + Set.new(%w(
          match raise
        ))
      end

      state :root do
        rule %r/\s+/m, Text
        rule %r/false|true|[(][)]|\[\]/, Name::Builtin::Pseudo
        rule %r/#{@@upper_id}(?=\s*[.])/, Name::Namespace, :dotted
        rule %r/`#{@@id}/, Name::Tag
        rule @@upper_id, Name::Class
        rule %r/[(][*](?![)])/, Comment, :comment
        rule @@id do |m|
          match = m[0]
          if self.class.keywords.include? match
            token Keyword
          elsif self.class.word_operators.include? match
            token Operator::Word
          elsif self.class.primitives.include? match
            token Keyword::Type
          else
            token Name
          end
        end

        rule %r/[(){}\[\];]+/, Punctuation
        rule @@operator, Operator

        rule %r/-?\d[\d_]*(.[\d_]*)?(e[+-]?\d[\d_]*)/i, Num::Float
        rule %r/0x\h[\h_]*/i, Num::Hex
        rule %r/0o[0-7][0-7_]*/i, Num::Oct
        rule %r/0b[01][01_]*/i, Num::Bin
        rule %r/\d[\d_]*/, Num::Integer

        rule %r/'(?:(\\[\\"'ntbr ])|(\\[0-9]{3})|(\\x\h{2}))'/, Str::Char
        rule %r/'[.]'/, Str::Char
        rule %r/'/, Keyword
        rule %r/"/, Str::Double, :string
        rule %r/[~?]#{@@id}/, Name::Variable
      end

      state :comment do
        rule %r/[^(*)]+/, Comment
        rule(/[(][*]/) { token Comment; push }
        rule %r/[*][)]/, Comment, :pop!
        rule %r/[(*)]/, Comment
      end
    end
  end
end
