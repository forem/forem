# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Nix < RegexLexer
      title 'Nix'
      desc 'The Nix expression language (https://nixos.org/nix/manual/#ch-expression-language)'
      tag 'nix'
      aliases 'nixos'
      filenames '*.nix'

      state :whitespaces do
        rule %r/^\s*\n\s*$/m, Text
        rule %r/\s+/, Text
      end

      state :comment do
        rule %r/#.*$/, Comment
        rule %r(/\*), Comment, :multiline_comment
      end

      state :multiline_comment do
        rule %r(\*/), Comment, :pop!
        rule %r/./, Comment
      end

      state :number do
        rule %r/[0-9]/, Num::Integer
      end

      state :null do
        rule %r/(null)/, Keyword::Constant
      end

      state :boolean do
        rule %r/(true|false)/, Keyword::Constant
      end

      state :binding do
        rule %r/[a-zA-Z_][a-zA-Z0-9-]*/, Name::Variable
      end

      state :path do
        word = "[a-zA-Z0-9\._-]+"
        section = "(\/#{word})"
        prefix = "[a-z\+]+:\/\/"
        root = /#{section}+/.source
        tilde = /~#{section}+/.source
        basic = /#{word}(\/#{word})+/.source
        url = /#{prefix}(\/?#{basic})/.source
        rule %r/(#{root}|#{tilde}|#{basic}|#{url})/, Str::Other
      end

      state :string do
        rule %r/"/, Str::Double, :double_quoted_string
        rule %r/''/, Str::Double, :indented_string
      end

      state :string_content do
        rule %r/\\./, Str::Escape
        rule %r/\$\$/, Str::Escape
        rule %r/\${/, Str::Interpol, :string_interpolated_arg
      end

      state :indented_string_content do
        rule %r/'''/, Str::Escape
        rule %r/''\$/, Str::Escape
        rule %r/\$\$/, Str::Escape
        rule %r/''\\./, Str::Escape
        rule %r/\${/, Str::Interpol, :string_interpolated_arg
      end

      state :string_interpolated_arg do
        mixin :expression
        rule %r/}/, Str::Interpol, :pop!
      end

      state :indented_string do
        mixin :indented_string_content
        rule %r/''/, Str::Double, :pop!
        rule %r/./, Str::Double
      end

      state :double_quoted_string do
        mixin :string_content
        rule %r/"/, Str::Double, :pop!
        rule %r/./, Str::Double
      end

      state :operator do
        rule %r/(\.|\?|\+\+|\+|!=|!|\/\/|\=\=|&&|\|\||->|\/|\*|-|<|>|<=|=>)/, Operator
      end

      state :assignment do
        rule %r/(=)/, Operator
        rule %r/(@)/, Operator
      end

      state :accessor do
        rule %r/(\$)/, Punctuation
      end

      state :delimiter do
        rule %r/(;|,|:)/, Punctuation
      end

      state :atom_content do
        mixin :expression
        rule %r/\)/, Punctuation, :pop!
      end

      state :atom do
        rule %r/\(/, Punctuation, :atom_content
      end

      state :list do
        rule %r/\[/, Punctuation, :list_content
      end

      state :list_content do
        rule %r/\]/, Punctuation, :pop!
        mixin :expression
      end

      state :set do
        rule %r/{/, Punctuation, :set_content
      end

      state :set_content do
        rule %r/}/, Punctuation, :pop!
        mixin :expression
      end

      state :expression do
        mixin :ignore
        mixin :comment
        mixin :boolean
        mixin :null
        mixin :number
        mixin :path
        mixin :string
        mixin :keywords
        mixin :operator
        mixin :accessor
        mixin :assignment
        mixin :delimiter
        mixin :binding
        mixin :atom
        mixin :set
        mixin :list
      end

      state :keywords do
        mixin :keywords_namespace
        mixin :keywords_declaration
        mixin :keywords_conditional
        mixin :keywords_reserved
        mixin :keywords_builtin
      end

      state :keywords_namespace do
        keywords = %w(with in inherit)
        rule %r/(?:#{keywords.join('|')})\b/, Keyword::Namespace
      end

      state :keywords_declaration do
        keywords = %w(let)
        rule %r/(?:#{keywords.join('|')})\b/, Keyword::Declaration
      end

      state :keywords_conditional do
        keywords = %w(if then else)
        rule %r/(?:#{keywords.join('|')})\b/, Keyword
      end

      state :keywords_reserved do
        keywords = %w(rec assert map)
        rule %r/(?:#{keywords.join('|')})\b/, Keyword::Reserved
      end

      state :keywords_builtin do
        keywords = %w(
          abort
          baseNameOf
          builtins
          derivation
          fetchTarball
          import
          isNull
          removeAttrs
          throw
          toString
        )
        rule %r/(?:#{keywords.join('|')})\b/, Keyword::Reserved
      end

      state :ignore do
        mixin :whitespaces
      end

      state :root do
        mixin :ignore
        mixin :expression
      end

      start do
      end
    end
  end
end
