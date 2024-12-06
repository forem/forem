# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Syzlang < RegexLexer
      title "Syzlang"
      desc "Syscall description language used by syzkaller"
      tag 'syzlang'

      def self.keywords
        @keywords ||= Set.new %w(
          align breaks_returns dec define disabled hex ignore_return in incdir
          include inet inout oct opt out packed parent prog_timeout pseudo
          resource size syscall timeout type varlen
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          array bitsize bool16 bool32 bool64 bool8 boolptr buffer bytesize
          bytesize2 bytesize4 bytesize8 const csum filename fileoff flags fmt
          int16 int16be int32 int32be int64 int64be int8 int8be intptr len
          offsetof optional proc ptr ptr64 string stringnoz text vma vma64 void
        )
      end

      comment = /#.*$/
      inline_spaces = /[ \t]+/
      spaces = /\s+/

      state :inline_break do
        rule inline_spaces, Text
        rule %r//, Text, :pop!
      end

      state :space_break do
        rule spaces, Text
        rule comment, Comment
        rule %r//, Text, :pop!
      end

      id = /[a-zA-Z_][a-zA-Z0-9_]*/
      num_id = /[a-zA-Z0-9_]+/

      state :mixin_name do
        rule id, Name
      end

      state :mixin_number do
        rule %r/-?0x[\da-f]+/i, Num::Hex
        rule %r/-?\d+/, Num::Integer
        rule %r/'[^']?'/, Str::Char
      end

      state :mixin_string do
        rule %r/"[^"]*"/, Str::Double
        rule %r/`[^`]*`/, Str::Backtick
      end

      state :mixin_term do
        mixin :mixin_number
        mixin :mixin_string

        # Keywords.
        rule id do |m|
          if self.class.keywords.include?(m[0])
            token Keyword
          elsif self.class.keywords_type.include?(m[0])
            token Keyword::Type
          else
            token Name
          end
        end

        # Ranges.
        rule %r/:/, Punctuation

        # "struct$type" struct name format.
        rule %r/\$/, Name
      end

      state :term_list do
        rule spaces, Text
        rule comment, Comment
        mixin :mixin_term
        rule %r/\[/, Punctuation, :term_list
        rule %r/,/, Punctuation
        rule %r/[\]\)]/, Punctuation, :pop!
      end

      state :arg_type do
        mixin :mixin_term
        rule %r/\[/, Punctuation, :term_list
        rule %r//, Text, :pop!
      end

      state :include do
        rule %r/(<)([^>]+)(>)/ do |m|
          groups Punctuation, Str, Punctuation
        end
        rule %r//, Text, :pop!
      end

      state :define_name do
        mixin :mixin_name
        rule %r//, Text, :pop!
      end

      state :define_exp do
        mixin :mixin_name
        mixin :mixin_number
        mixin :mixin_string
        rule %r/[~!%\^&\*\-\+\/\|<>\?:]/, Operator
        rule %r/[\(\){}\[\];,]/, Punctuation
        rule inline_spaces, Text
        rule %r//, Text, :pop!
      end

      state :resource_name do
        mixin :mixin_name
        rule %r//, Text, :pop!
      end

      state :resource_type do
        rule %r/\[/, Punctuation, :arg_type
        rule %r/\]/, Punctuation, :pop!
      end

      state :resource_values do
        rule %r/:/ do
          token Punctuation
          push :resource_values_list
          push :space_break
        end
        rule %r//, Text, :pop!
      end

      state :resource_values_list do
        rule inline_spaces, Text
        mixin :mixin_name
        mixin :mixin_number
        mixin :mixin_string
        rule %r/,/, Punctuation, :space_break
        rule %r//, Text, :pop!
      end

      state :flags_list do
        rule inline_spaces, Text
        rule %r/\./, Punctuation
        mixin :mixin_name
        mixin :mixin_number
        mixin :mixin_string
        rule %r/,/, Punctuation, :space_break
        rule %r//, Punctuation, :pop!
      end

      state :syscall_args do
        rule spaces, Text
        rule comment, Comment
        rule %r/\./, Punctuation
        rule id do
          token Name
          push :arg_type
          push :space_break
        end
        rule %r/,/, Punctuation
        rule %r/\)/, Punctuation, :pop!
      end

      state :syscall_retval do
        mixin :mixin_name
        rule %r//, Text, :pop!
      end

      state :syscall_mods do
        rule %r/\(/, Punctuation, :term_list
        rule %r//, Text, :pop!
      end

      state :struct_fields do
        rule id do
          token Name
          push :space_break
          push :struct_field_mods
          push :inline_break
          push :arg_type
          push :space_break
        end
        rule %r/[}\]]/, Punctuation, :pop!
      end

      state :struct_field_mods do
        rule %r/\(/, Punctuation, :term_list
        rule %r//, Text, :pop!
      end

      state :struct_mods do
        rule %r/\[/, Punctuation, :term_list
        rule %r//, Text, :pop!
      end

      state :type_name do
        mixin :mixin_name
        rule %r//, Text, :pop!
      end

      state :type_args do
        rule %r/\[/, Punctuation, :type_args_list
        rule %r//, Text, :pop!
      end

      state :type_args_list do
        rule spaces, Text
        rule comment, Comment
        mixin :mixin_name
        rule %r/,/, Punctuation
        rule %r/\]/, Punctuation, :pop!
      end

      state :type_body do
        rule %r/[{\[]/ do
          token Punctuation
          pop!
          push :space_break
          push :struct_mods
          push :inline_break
          push :struct_fields
          push :space_break
        end
        rule %r// do
          pop!
          push :arg_type
        end
      end

      state :root do
        # Whitespace.
        rule spaces, Text

        # Comments.
        rule comment, Comment

        # Includes.
        rule %r/(include|incdir)/ do
          token Keyword
          push :include
          push :space_break
        end

        # Defines.
        rule %r/define/ do
          token Keyword
          push :define_exp
          push :space_break
          push :define_name
          push :space_break
        end

        # Resources.
        rule %r/resource/ do
          token Keyword
          push :resource_values
          push :inline_break
          push :resource_type
          push :inline_break
          push :resource_name
          push :space_break
        end

        # Flags and strings.
        rule %r/(#{id}|_)(#{spaces})(=)/ do |m|
          if m[1] == "_"
            groups Keyword, Text, Punctuation
          else
            groups Name, Text, Punctuation
          end
          push :flags_list
          push :space_break
        end

        # Syscalls.
        rule %r/(#{id})(\$)?(#{num_id})?(#{spaces})?(\()/ do |m|
          groups Name::Function, Punctuation, Name::Function::Magic, Text, Punctuation
          push :syscall_mods
          push :inline_break
          push :syscall_retval
          push :inline_break
          push :syscall_args
          push :space_break
        end

        # Structs and unions.
        rule %r/(#{id}|#{id}\$#{num_id})(#{spaces})?([{\[])/ do |m|
          groups Name, Text, Punctuation
          push :inline_break
          push :struct_mods
          push :inline_break
          push :struct_fields
          push :space_break
        end

        # Types.
        rule %r/type/ do
          token Keyword
          push :type_body
          push :space_break
          push :type_args
          push :type_name
          push :space_break
        end
      end

    end
  end
end
