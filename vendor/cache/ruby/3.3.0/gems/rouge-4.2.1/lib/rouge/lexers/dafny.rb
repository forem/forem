# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Dafny < RegexLexer
      title "Dafny"
      desc "The Dafny programming language (github.com/dafny-lang/dafny)"
      tag "dafny"
      filenames "*.dfy"
      mimetypes "text/x-dafny"

      keywords = %w(
        abstract allocated assert assume
        break by
        calc case class codatatype const constructor
        datatype decreases downto
        else ensures exists expect export extends
        false for forall fresh function
        ghost greatest
        if import include invariant iterator
        label least lemma
        match method modifies modify module
        nameonly new newtype null
        old opened
        predicate print provides
        reads refines requires return returns reveal reveals
        static
        then this to trait true twostate type
        unchanged
        var
        while witness
        yield yields
      )

      literals = %w{ true false null }

      textOperators = %w{ as is in }

      types = %w(bool char int real string nat
                 array array? object object? ORDINAL
                 seq set iset map imap multiset )

      idstart = /[0-9a-zA-Z?]/
      idchar = /[0-9a-zA-Z_'?]/
      id = /#{idstart}#{idchar}*/

      arrayType = /array(?:1[0-9]+|[2-9][0-9]*)\??(?!#{idchar})/
      bvType = /bv(?:0|[1-9][0-9]*)(?!#{idchar})/

      digit = /\d/
      digits = /#{digit}+(?:_#{digit}+)*/
      bin_digits = /[01]+(?:_[01]+)*/
      hex_digit = /(?:[0-9a-fA-F])/
      hex_digits = /#{hex_digit}+(?:_#{hex_digit}+)*/

      cchar = /(?:[^\\'\n\r]|\\["'ntr\\0])/
      schar = /(?:[^\\"\n\r]|\\["'ntr\\0])/
      uchar = /(?:\\u#{hex_digit}{4})/

      ## IMPORTANT: Rules are ordered, which allows later rules to be 
      ## simpler than they would otherwise be
      state :root do
        rule %r(/\*), Comment::Multiline, :comment
        rule %r(//.*?$), Comment::Single
        rule %r(\*/), Error          # should not have closing comment in :root
                                     # is an improperly nested comment

        rule %r/'#{cchar}'/, Str::Char           # standard or escape char
        rule %r/'#{uchar}'/, Str::Char           # unicode char
        rule %r/'[^'\n\r]*'/, Error              # bad any other enclosed char
        rule %r/'[^'\n\r]*$/, Error              # bad unclosed char

        rule %r/"(?:#{schar}|#{uchar})*"/, Str::Double        # valid string
        rule %r/".*"/, Error                     # anything else that is closed
        rule %r/".*$/, Error                     # bad unclosed string

        rule %r/@"([^"]|"")*"/, Str::Other     # valid verbatim string
        rule %r/@".*/m, Error             # anything else , multiline unclosed


        rule %r/#{digits}\.#{digits}(?!#{idchar})/, Num::Float
        rule %r/0b#{bin_digits}(?!#{idchar})/, Num::Bin
        rule %r/0b#{idchar}*/, Error
        rule %r/0x#{hex_digits}(?!#{idchar})/, Num::Hex
        rule %r/0x#{idchar}*/, Error
        rule %r/#{digits}(?!#{idchar})/, Num::Integer
        rule %r/_(?!#{idchar})/, Name
        rule %r/_[0-9_]+[_]?(?!#{idchar})/, Error
        rule %r/[0-9_]+_(?!#{idchar})/, Error
        rule %r/[0-9]#{idchar}+/, Error

        rule %r/#{arrayType}/, Keyword::Type
        rule %r/#{bvType}/, Keyword::Type

        rule id do |m|
          if types.include?(m[0])
            token Keyword::Type
          elsif literals.include?(m[0])
            token Keyword::Constant
          elsif textOperators.include?(m[0])
            token Operator::Word
          elsif keywords.include?(m[0])
            token Keyword::Reserved
          else
            token Name
          end
        end

        rule %r/\.\./, Operator
        rule %r/[*!%&<>\|^+=:.\/-]/, Operator
        rule %r/[\[\](){},;`]/, Punctuation

        rule %r/[^\S\n]+/, Text
        rule %r/\n/, Text
        rule %r/./, Error # Catchall
      end

      state :comment do
        rule %r(\*/), Comment::Multiline, :pop!
        rule %r(/\*), Comment::Multiline, :comment
        rule %r([^*/]+), Comment::Multiline
        rule %r(.), Comment::Multiline
      end

    end
  end
end
