# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Syzprog < RegexLexer
      title "Syzprog"
      desc "Program description language used by syzkaller"
      tag 'syzprog'

      def self.keywords
        @keywords ||= Set.new %w(
          ANY ANYBLOB ANYPTR ANYPTR64 ANYPTRS ANYRES16 ANYRES32 ANYRES64
          ANYRESDEC ANYRESHEX ANYRESOCT ANYUNION AUTO false nil true void
          async fail_nth rerun
        )
      end

      comment = /#.*$/
      inline_spaces = /[ \t]+/
      eol_spaces = /[\n\r]+/
      spaces = /\s+/

      id = /[a-zA-Z_][a-zA-Z0-9_]*/
      num_id = /[a-zA-Z0-9_]+/
      res_id = /r[0-9]+/

      state :inline_break do
        rule inline_spaces, Text
        rule %r//, Text, :pop!
      end

      state :eol_break do
        rule eol_spaces, Text
        rule comment, Comment
        rule %r//, Text, :pop!
      end

      state :space_break do
        rule spaces, Text
        rule comment, Comment
        rule %r//, Text, :pop!
      end

      state :mixin_number do
        rule %r/-?0x[\da-f]+/i, Num::Hex
        rule %r/-?\d+/, Num::Integer
      end

      state :mixin_string do
        rule %r/"[^"]*"/, Str::Double
        rule %r/`[^`]*`/, Str::Backtick
        rule %r/'[^']*'/, Str::Single
      end

      state :mixin_term do
        mixin :mixin_number
        mixin :mixin_string

        rule %r/#{res_id}/, Keyword::Pseudo
        rule id do |m|
          if self.class.keywords.include?(m[0])
            token Keyword
          else
            token Name
          end
        end
      end

      state :mods_list do
        rule spaces, Text
        rule comment, Comment
        mixin :mixin_term
        rule %r/[,:]/, Punctuation
        rule %r/\)/, Punctuation, :pop!
      end

      state :syscall_mods do
        rule %r/\(/, Punctuation, :mods_list
        rule %r//, Text, :pop!
      end

      state :syscall_args do
        rule spaces, Text
        rule comment, Comment
        mixin :mixin_term
        mixin :mixin_number
        mixin :mixin_string
        # This punctuation is a part of the syntax:
        rule %r/[@&=,<>{}\[\]]/, Punctuation
        # This punctuation is not, highlight just in case:
        rule %r/[!#\$%\^\*\-\+\/\|~:;.\?]/, Punctuation
        rule %r/\(/, Punctuation, :syscall_args
        rule %r/\)/, Punctuation, :pop!
      end

      state :root do
        # Whitespace.
        rule spaces, Text

        # Comments.
        rule comment, Comment

        # Return values.
        rule %r/(#{res_id})(#{spaces})(=)/ do
          groups Keyword::Pseudo, Text, Punctuation
        end

        # Syscalls.
        rule %r/(#{id})(\$)?(#{num_id})?(#{spaces})?(\()/ do |m|
          groups Name::Function, Punctuation, Name::Function::Magic, Text, Punctuation
          push :syscall_mods
          push :inline_break
          push :syscall_args
          push :space_break
        end

      end

    end
  end
end
