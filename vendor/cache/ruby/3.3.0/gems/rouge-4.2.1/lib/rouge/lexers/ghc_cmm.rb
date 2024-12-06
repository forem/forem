# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# C minus minus (Cmm) is a pun on the name C++. It's an intermediate language
# of the Glasgow Haskell Compiler (GHC) that is very similar to C, but with
# many features missing and some special constructs.
#
# Cmm is a dialect of C--. The goal of this lexer is to use what GHC produces
# and parses (Cmm); C-- itself is not supported.
#
# https://gitlab.haskell.org/ghc/ghc/wikis/commentary/compiler/cmm-syntax
#
module Rouge
  module Lexers
    class GHCCmm < RegexLexer
      title "GHC Cmm (C--)"
      desc "GHC Cmm is the intermediate representation of the GHC Haskell compiler"
      tag 'ghc-cmm'
      filenames '*.cmm', '*.dump-cmm', '*.dump-cmm-*'
      aliases 'cmm'

      ws = %r(\s|//.*?\n|/[*](?:[^*]|(?:[*][^/]))*[*]+/)mx

      # Make sure that this is not a preprocessor macro, e.g. `#if` or `#define`.
      id = %r((?!\#[a-zA-Z])[\w#\$%']+)

      complex_id = %r(
        (?:[\w#$%']|\(\)|\(,\)|\[\]|[0-9])*
        (?:[\w#$%']+)
      )mx

      state :root do
        rule %r/\s+/m, Text

        # sections markers
        rule %r/^=====.*=====$/, Generic::Heading

        # timestamps
        rule %r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+ UTC$/, Comment::Single

        mixin :detect_section
        mixin :preprocessor_macros

        mixin :info_tbls
        mixin :comments
        mixin :literals
        mixin :keywords
        mixin :types
        mixin :infos
        mixin :names
        mixin :operators

        # escaped newline
        rule %r/\\\n/, Text

        # rest is Text
        rule %r/./, Text
      end

      state :detect_section do
        rule %r/(section)(\s+)/ do |m|
          token Keyword, m[1]
          token Text, m[2]
          push :section
        end
      end

      state :section do
        rule %r/"(data|cstring|text|rodata|relrodata|bss)"/, Name::Builtin

        rule %r/{/, Punctuation, :pop!

        mixin :names
        mixin :operators
        mixin :keywords

        rule %r/\s+/, Text
      end

      state :preprocessor_macros do
        rule %r/#(include|endif|else|if)/, Comment::Preproc

        rule %r{
            (\#define)
            (#{ws}*)
            (#{id})
          }mx do |m|
          token Comment::Preproc, m[1]
          recurse m[2]
          token Name::Label, m[3]
        end
      end

      state :info_tbls do
        rule %r/({ )(info_tbls)(:)/ do |m|
          token Punctuation, m[1]
          token Name::Entity, m[2]
          token Punctuation, m[3]

          push :info_tbls_body
        end
      end

      state :info_tbls_body do
        rule %r/}/, Punctuation, :pop!
        rule %r/{/, Punctuation, :info_tbls_body

        rule %r/(?=label:)/ do
          push :label
        end

        rule %r{(\()(#{complex_id})(,)}mx do |m|
          token Punctuation, m[1]
          token Name::Label, m[2]
          token Punctuation, m[3]
        end

        mixin :literals
        mixin :infos
        mixin :keywords
        mixin :operators

        rule %r/#{id}/, Text
        rule %r/\s+/, Text
      end

      state :label do
        mixin :infos
        mixin :names
        mixin :keywords
        mixin :operators

        rule %r/[^\S\n]+/, Text # Tab, space, etc. but not newline!
        rule %r/\n/, Text, :pop!
      end

      state :comments do
        rule %r/\/{2}.*/, Comment::Single
        rule %r/\(likely.*?\)/, Comment
        rule %r/\/\*.*?\*\//m, Comment::Multiline
      end

      state :literals do
        rule %r/-?[0-9]+\.[0-9]+/, Literal::Number::Float
        rule %r/-?[0-9]+/, Literal::Number::Integer
        rule %r/"/, Literal::String::Delimiter, :literal_string
      end

      state :literal_string do
        # quotes
        rule %r/\\./, Literal::String::Escape
        rule %r/%./, Literal::String::Symbol
        rule %r/"/, Literal::String::Delimiter, :pop!
        rule %r/./, Literal::String
      end

      state :operators do
        rule %r/\.\./, Operator
        rule %r/[+\-*\/<>=!&|~]/, Operator
        rule %r/[\[\].{}:;,()]/, Punctuation
      end

      state :keywords do
        rule %r/(const)(\s+)/ do |m|
          token Keyword::Constant, m[1]
          token Text, m[2]
        end

        rule %r/"/, Literal::String::Double

        rule %r/(switch)([^{]*)({)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Punctuation, m[3]
        end

        rule %r/(arg|result)(#{ws}+)(hints)(:)/ do |m|
          token Name::Property, m[1]
          recurse m[2]
          token Name::Property, m[3]
          token Punctuation, m[4]
        end

        rule %r/(returns)(#{ws}*)(to)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Keyword, m[3]
        end

        rule %r/(never)(#{ws}*)(returns)/ do |m|
          token Keyword, m[1]
          recurse m[2]
          token Keyword, m[3]
        end

        rule %r{(return)(#{ws}*)(\()} do |m|
          token Keyword, m[1]
          recurse m[2]
          token Punctuation, m[3]
        end

        rule %r{(if|else|goto|call|offset|import|jump|ccall|foreign|prim|case|unwind|export|reserve|push)(#{ws})} do |m|
          token Keyword, m[1]
          recurse m[2]
        end

        rule %r{(default)(#{ws}*)(:)} do |m|
          token Keyword, m[1]
          recurse m[2]
          token Punctuation, m[3]
        end
      end

      state :types do
        # Memory access: `type[42]`
        # Note: Only a token for type is produced.
        rule %r/(#{id})(?=\[[^\]])/ do |m|
          token Keyword::Type, m[1]
        end

        # Array type: `type[]`
        rule %r/(#{id}\[\])/ do |m|
          token Keyword::Type, m[1]
        end

        # Capture macro substitutions before lexing typed declarations
        # I.e. there is no type in `PREPROCESSOR_MACRO_VARIABLE someFun()`
        rule %r{
                (^#{id})
                (#{ws}+)
                (#{id})
                (#{ws}*)
                (\()
              }mx do |m|
          token Name::Label, m[1]
          recurse m[2]
          token Name::Function, m[3]
          recurse m[4]
          token Punctuation, m[5]
        end

        # Type in variable or parameter declaration:
        #   `type /* optional whitespace */ var_name /* optional whitespace */;`
        #   `type /* optional whitespace */ var_name /* optional whitespace */, var_name2`
        #   `(type /* optional whitespace */ var_name /* optional whitespace */)`
        # Note: Only the token for type is produced here.
        rule %r{
                (^#{id})
                (#{ws}+)
                (#{id})
              }mx do |m|
          token Keyword::Type, m[1]
          recurse m[2]
          token Name::Label, m[3]
        end
      end

      state :infos do
        rule %r/(args|res|upd|label|rep|srt|arity|fun_type|arg_space|updfr_space)(:)/ do |m|
          token Name::Property, m[1]
          token Punctuation, m[2]
        end

        rule %r/(stack_info)(:)/ do |m|
          token Name::Entity, m[1]
          token Punctuation, m[2]
        end
      end

      state :names do
        rule %r/(::)(#{ws}*)([A-Z]\w+)/ do |m|
          token Operator, m[1]
          recurse m[2]
          token Keyword::Type, m[3]
        end

        rule %r/<(#{id})>/, Name::Builtin

        rule %r/(Sp|SpLim|Hp|HpLim|HpAlloc|BaseReg|CurrentNursery|CurrentTSO|R\d{1,2}|gcptr)(?!#{id})/, Name::Variable::Global
        rule %r/([A-Z]#{id})(\.)/ do |m|
          token Name::Namespace, m[1]
          token Punctuation, m[2]
          push :namespace_name
        end

        # Inline function calls:
        # ```
        #  arg1 `lt` arg2
        # ```
        rule %r/(`)(#{id})(`)/ do |m|
          token Punctuation, m[1]
          token Name::Function, m[2]
          token Punctuation, m[3]
        end

        # Function: `name /* optional whitespace */ (`
        # Function (arguments via explicit stack handling): `name /* optional whitespace */ {`
        rule %r{(?=
                  #{complex_id}
             #{ws}*
                  [\{\(]
                )}mx do
          push :function
        end

        rule %r/CLOSURE/, Keyword::Type
        rule %r/#{complex_id}/, Name::Label
      end

      state :namespace_name do
        rule %r/([A-Z]#{id})(\.)/ do |m|
          token Name::Namespace, m[1]
          token Punctuation, m[2]
        end

        rule %r{(#{complex_id})(#{ws}*)([\{\(])}mx do |m|
          token Name::Function, m[1]
          recurse m[2]
          token Punctuation, m[3]
          pop!
        end

        rule %r/#{complex_id}/, Name::Label, :pop!

        rule %r/(?=.)/m do
          pop!
        end
      end

      state :function do
        rule %r/INFO_TABLE_FUN|INFO_TABLE_CONSTR|INFO_TABLE_SELECTOR|INFO_TABLE_RET|INFO_TABLE/, Name::Builtin
        rule %r/%#{id}/, Name::Builtin
        rule %r/#{complex_id}/, Name::Function
        rule %r/\s+/, Text
        rule %r/[({]/, Punctuation, :pop!
        mixin :comments
      end
    end
  end
end
