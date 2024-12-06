# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class FSharp < RegexLexer
      title "FSharp"
      desc 'F# (fsharp.net)'
      tag 'fsharp'
      filenames '*.fs', '*.fsi', '*.fsx'
      mimetypes 'application/fsharp-script', 'text/x-fsharp', 'text/x-fsi'

      def self.keywords
        @keywords ||= Set.new %w(
          abstract and as assert base begin class default delegate do
          done downcast downto elif else end exception extern false
          finally for fun function global if in inherit inline interface
          internal lazy let let! match member module mutable namespace
          new not null of open or override private public rec return
          return! select static struct then to true try type upcast
          use use! val void when while with yield yield! sig atomic
          break checked component const constraint constructor
          continue eager event external fixed functor include method
          mixin object parallel process protected pure sealed tailcall
          trait virtual volatile
        )
      end

      def self.keyopts
        @keyopts ||= Set.new %w(
          != # & && ( ) * \+ , - -. -> . .. : :: := :> ; ;; < <- =
          > >] >} ? ?? [ [< [> [| ] _ ` { {< | |] } ~ |> <| <>
        )
      end

      def self.word_operators
        @word_operators ||= Set.new %w(and asr land lor lsl lxor mod or)
      end

      def self.primitives
        @primitives ||= Set.new %w(unit int float bool string char list array)
      end

      operator = %r([\[\];,{}_()!$%&*+./:<=>?@^|~#-]+)
      id = /([a-z][\w']*)|(``[^`\n\r\t]+``)/i
      upper_id = /[A-Z][\w']*/

      state :root do
        rule %r/\s+/m, Text
        rule %r/false|true|[(][)]|\[\]/, Name::Builtin::Pseudo
        rule %r/#{upper_id}(?=\s*[.])/, Name::Namespace, :dotted
        rule upper_id, Name::Class
        rule %r/[(][*](?![)])/, Comment, :comment
        rule %r(//.*?$), Comment::Single
        rule id do |m|
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

        rule operator do |m|
          match = m[0]
          if self.class.keyopts.include? match
            token Punctuation
          else
            token Operator
          end
        end

        rule %r/-?\d[\d_]*(.[\d_]*)?(e[+-]?\d[\d_]*)/i, Num::Float
        rule %r/0x\h[\h_]*/i, Num::Hex
        rule %r/0o[0-7][0-7_]*/i, Num::Oct
        rule %r/0b[01][01_]*/i, Num::Bin
        rule %r/\d[\d_]*/, Num::Integer

        rule %r/'(?:(\\[\\"'ntbr ])|(\\[0-9]{3})|(\\x\h{2}))'/, Str::Char
        rule %r/'[.]'/, Str::Char
        rule %r/'/, Keyword
        rule %r/"/, Str::Double, :string
        rule %r/[~?]#{id}/, Name::Variable
      end

      state :comment do
        rule %r/[^(*)]+/, Comment
        rule(/[(][*]/) { token Comment; push }
        rule %r/[*][)]/, Comment, :pop!
        rule %r/[(*)]/, Comment
      end

      state :string do
        rule %r/[^\\"]+/, Str::Double
        mixin :escape_sequence
        rule %r/\\\n/, Str::Double
        rule %r/"/, Str::Double, :pop!
      end

      state :escape_sequence do
        rule %r/\\[\\"'ntbr]/, Str::Escape
        rule %r/\\\d{3}/, Str::Escape
        rule %r/\\x\h{2}/, Str::Escape
      end

      state :dotted do
        rule %r/\s+/m, Text
        rule %r/[.]/, Punctuation
        rule %r/#{upper_id}(?=\s*[.])/, Name::Namespace
        rule upper_id, Name::Class, :pop!
        rule id, Name, :pop!
        rule %r/\[/, Punctuation, :pop!
      end
    end
  end
end
