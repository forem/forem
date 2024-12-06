# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Lua < RegexLexer
      title "Lua"
      desc "Lua (http://www.lua.org)"
      tag 'lua'
      filenames '*.lua', '*.wlua'

      mimetypes 'text/x-lua', 'application/x-lua'

      option :function_highlighting, 'Whether to highlight builtin functions (default: true)'
      option :disabled_modules, 'builtin modules to disable'

      def initialize(opts={})
        @function_highlighting = opts.delete(:function_highlighting) { true }
        @disabled_modules = opts.delete(:disabled_modules) { [] }
        super(opts)
      end

      def self.detect?(text)
        return true if text.shebang? 'lua'
      end

      def self.builtins
        Kernel::load File.join(Lexers::BASE_DIR, 'lua/keywords.rb')
        builtins
      end

      def builtins
        return [] unless @function_highlighting

        @builtins ||= Set.new.tap do |builtins|
          self.class.builtins.each do |mod, fns|
            next if @disabled_modules.include? mod
            builtins.merge(fns)
          end
        end
      end

      state :root do
        # lua allows a file to start with a shebang
        rule %r(#!(.*?)$), Comment::Preproc
        rule %r//, Text, :base
      end

      state :base do
        rule %r(--\[(=*)\[.*?\]\1\])m, Comment::Multiline
        rule %r(--.*$), Comment::Single

        rule %r((?i)(\d*\.\d+|\d+\.\d*)(e[+-]?\d+)?'), Num::Float
        rule %r((?i)\d+e[+-]?\d+), Num::Float
        rule %r((?i)0x[0-9a-f]*), Num::Hex
        rule %r(\d+), Num::Integer

        rule %r(\n), Text
        rule %r([^\S\n]), Text
        # multiline strings
        rule %r(\[(=*)\[.*?\]\1\])m, Str

        rule %r((==|~=|<=|>=|\.\.\.|\.\.|[=+\-*/%^<>#])), Operator
        rule %r([\[\]\{\}\(\)\.,:;]), Punctuation
        rule %r((and|or|not)\b), Operator::Word

        rule %r((break|do|else|elseif|end|for|if|in|repeat|return|then|until|while)\b), Keyword
        rule %r((local)\b), Keyword::Declaration
        rule %r((true|false|nil)\b), Keyword::Constant

        rule %r((function)\b), Keyword, :function_name

        rule %r([A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?) do |m|
          name = m[0]
          if name == "gsub"
            token Name::Builtin
            push :gsub
          elsif self.builtins.include?(name)
            token Name::Builtin
          elsif name =~ /\./
            a, b = name.split('.', 2)
            token Name, a
            token Punctuation, '.'
            token Name, b
          else
            token Name
          end
        end

        rule %r('), Str::Single, :escape_sqs
        rule %r("), Str::Double, :escape_dqs
      end

      state :function_name do
        rule %r/\s+/, Text
        rule %r((?:([A-Za-z_][A-Za-z0-9_]*)(\.))?([A-Za-z_][A-Za-z0-9_]*)) do
          groups Name::Class, Punctuation, Name::Function
          pop!
        end
        # inline function
        rule %r(\(), Punctuation, :pop!
      end

      state :gsub do
        rule %r/\)/, Punctuation, :pop!
        rule %r/[(,]/, Punctuation
        rule %r/\s+/, Text
        rule %r/"/, Str::Regex, :regex
      end

      state :regex do
        rule %r(") do
          token Str::Regex
          goto :regex_end
        end

        rule %r/\[\^?/, Str::Escape, :regex_group
        rule %r/\\./, Str::Escape
        rule %r{[(][?][:=<!]}, Str::Escape
        rule %r/[{][\d,]+[}]/, Str::Escape
        rule %r/[()?]/, Str::Escape
        rule %r/./, Str::Regex
      end

      state :regex_end do
        rule %r/[$]+/, Str::Regex, :pop!
        rule(//) { pop! }
      end

      state :regex_group do
        rule %r(/), Str::Escape
        rule %r/\]/, Str::Escape, :pop!
        rule %r/(\\)(.)/ do |m|
          groups Str::Escape, Str::Regex
        end
        rule %r/./, Str::Regex
      end

      state :escape_sqs do
        mixin :string_escape
        mixin :sqs
      end

      state :escape_dqs do
        mixin :string_escape
        mixin :dqs
      end

      state :string_escape do
        rule %r(\\([abfnrtv\\"']|\d{1,3})), Str::Escape
      end

      state :sqs do
        rule %r('), Str::Single, :pop!
        rule %r([^']+), Str::Single
      end

      state :dqs do
        rule %r("), Str::Double, :pop!
        rule %r([^"]+), Str::Double
      end
    end
  end
end
