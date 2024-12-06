# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class YAML < RegexLexer
      title "YAML"
      desc "Yaml Ain't Markup Language (yaml.org)"
      mimetypes 'text/x-yaml'
      tag 'yaml'
      aliases 'yml'
      filenames '*.yaml', '*.yml'

      # Documentation: https://yaml.org/spec/1.2/spec.html

      def self.detect?(text)
        # look for the %YAML directive
        return true if text =~ /\A\s*%YAML/m
      end

      # NB: Tabs are forbidden in YAML, which is why you see things
      # like /[ ]+/.

      # reset the indentation levels
      def reset_indent
        puts "    yaml: reset_indent" if @debug
        @indent_stack = [0]
        @next_indent = 0
        @block_scalar_indent = nil
      end

      def indent
        raise 'empty indent stack!' if @indent_stack.empty?
        @indent_stack.last
      end

      def dedent?(level)
        level < self.indent
      end

      def indent?(level)
        level > self.indent
      end

      # Save a possible indentation level
      def save_indent(match)
        @next_indent = match.size
        puts "    yaml: indent: #{self.indent}/#@next_indent" if @debug
        puts "    yaml: popping indent stack - before: #@indent_stack" if @debug
        if dedent?(@next_indent)
          @indent_stack.pop while dedent?(@next_indent)
          puts "    yaml: popping indent stack - after: #@indent_stack" if @debug
          puts "    yaml: indent: #{self.indent}/#@next_indent" if @debug

          # dedenting to a state not previously indented to is an error
          [match[0...self.indent], match[self.indent..-1]]
        else
          [match, '']
        end
      end

      def continue_indent(match)
        puts "    yaml: continue_indent" if @debug
        @next_indent += match.size
      end

      def set_indent(match, opts={})
        if indent < @next_indent
          puts "    yaml: indenting #{indent}/#{@next_indent}" if @debug
          @indent_stack << @next_indent
        end

        @next_indent += match.size unless opts[:implicit]
      end

      plain_scalar_start = /[^ \t\n\r\f\v?:,\[\]{}#&*!\|>'"%@`]/

      start { reset_indent }

      state :basic do
        rule %r/#.*$/, Comment::Single
      end

      state :root do
        mixin :basic

        rule %r/\n+/, Text

        # trailing or pre-comment whitespace
        rule %r/[ ]+(?=#|$)/, Text

        rule %r/^%YAML\b/ do
          token Name::Tag
          reset_indent
          push :yaml_directive
        end

        rule %r/^%TAG\b/ do
          token Name::Tag
          reset_indent
          push :tag_directive
        end

        # doc-start and doc-end indicators
        rule %r/^(?:---|\.\.\.)(?= |$)/ do
          token Name::Namespace
          reset_indent
          push :block_line
        end

        # indentation spaces
        rule %r/[ ]*(?!\s|$)/ do |m|
          text, err = save_indent(m[0])
          token Text, text
          token Error, err
          push :block_line; push :indentation
        end
      end

      state :indentation do
        rule(/\s*?\n/) { token Text; pop! 2 }
        # whitespace preceding block collection indicators
        rule %r/[ ]+(?=[-:?](?:[ ]|$))/ do |m|
          token Text
          continue_indent(m[0])
        end

        # block collection indicators
        rule(/[?:-](?=[ ]|$)/) do |m|
          set_indent m[0]
          token Punctuation::Indicator
        end

        # the beginning of a block line
        rule(/[ ]*/) { |m| token Text; continue_indent(m[0]); pop! }
      end

      # indented line in the block context
      state :block_line do
        # line end
        rule %r/[ ]*(?=#|$)/, Text, :pop!
        rule %r/[ ]+/, Text
        # tags, anchors, and aliases
        mixin :descriptors
        # block collections and scalars
        mixin :block_nodes
        # flow collections and quoed scalars
        mixin :flow_nodes

        # a plain scalar
        rule %r/(?=#{plain_scalar_start}|[?:-][^ \t\n\r\f\v])/ do
          token Name::Variable
          push :plain_scalar_in_block_context
        end
      end

      state :descriptors do
        # a full-form tag
        rule %r/!<[0-9A-Za-z;\/?:@&=+$,_.!~*'()\[\]%-]+>/, Keyword::Type

        # a tag in the form '!', '!suffix' or '!handle!suffix'
        rule %r(
          (?:![\w-]+)? # handle
          !(?:[\w;/?:@&=+$,.!~*\'()\[\]%-]*) # suffix
        )x, Keyword::Type

        # an anchor
        rule %r/&[\p{L}\p{Nl}\p{Nd}_-]+/, Name::Label

        # an alias
        rule %r/\*[\p{L}\p{Nl}\p{Nd}_-]+/, Name::Variable
      end

      state :block_nodes do
        # implicit key
        rule %r/([^#,?\[\]{}"'\n]+)(:)(?=\s|$)/ do |m|
          groups Name::Attribute, Punctuation::Indicator
          set_indent m[0], :implicit => true
        end

        # literal and folded scalars
        rule %r/[\|>][+-]?/ do
          token Punctuation::Indicator
          push :block_scalar_content
          push :block_scalar_header
        end
      end

      state :flow_nodes do
        rule %r/\[/, Punctuation::Indicator, :flow_sequence
        rule %r/\{/, Punctuation::Indicator, :flow_mapping
        rule %r/'/, Str::Single, :single_quoted_scalar
        rule %r/"/, Str::Double, :double_quoted_scalar
      end

      state :flow_collection do
        rule %r/\s+/m, Text
        mixin :basic
        rule %r/[?:,]/, Punctuation::Indicator
        mixin :descriptors
        mixin :flow_nodes

        rule %r/(?=#{plain_scalar_start})/ do
          push :plain_scalar_in_flow_context
        end
      end

      state :flow_sequence do
        rule %r/\]/, Punctuation::Indicator, :pop!
        mixin :flow_collection
      end

      state :flow_mapping do
        rule %r/\}/, Punctuation::Indicator, :pop!
        mixin :flow_collection
      end

      state :block_scalar_content do
        rule %r/\n+/, Text

        # empty lines never dedent, but they might be part of the scalar.
        rule %r/^[ ]+$/ do |m|
          text = m[0]
          indent_size = text.size

          indent_mark = @block_scalar_indent || indent_size

          token Text, text[0...indent_mark]
          token Name::Constant, text[indent_mark..-1]
        end

        # TODO: ^ doesn't actually seem to affect the match at all.
        # Find a way to work around this limitation.
        rule %r/^[ ]*/ do |m|
          token Text

          indent_size = m[0].size

          dedent_level = @block_scalar_indent || self.indent
          @block_scalar_indent ||= indent_size

          if indent_size < dedent_level
            save_indent m[0]
            pop!
            push :indentation
          end
        end

        rule %r/[^\n\r\f\v]+/, Str
      end

      state :block_scalar_header do
        # optional indentation indicator and chomping flag, in either order
        rule %r(
          (
            ([1-9])[+-]? | [+-]?([1-9])?
          )(?=[ ]|$)
        )x do |m|
          @block_scalar_indent = nil
          goto :ignored_line
          next if m[0].empty?

          increment = m[1] || m[2]
          if increment
            @block_scalar_indent = indent + increment.to_i
          end

          token Punctuation::Indicator
        end
      end

      state :ignored_line do
        mixin :basic
        rule %r/[ ]+/, Text
        rule %r/\n/, Text, :pop!
      end

      state :quoted_scalar_whitespaces do
        # leading and trailing whitespace is ignored
        rule %r/^[ ]+/, Text
        rule %r/[ ]+$/, Text

        rule %r/\n+/m, Text

        rule %r/[ ]+/, Name::Variable
      end

      state :single_quoted_scalar do
        mixin :quoted_scalar_whitespaces
        rule %r/\\'/, Str::Escape
        rule %r/'/, Str, :pop!
        rule %r/[^\s']+/, Str
      end

      state :double_quoted_scalar do
        rule %r/"/, Str, :pop!
        mixin :quoted_scalar_whitespaces
        # escapes
        rule %r/\\[0abt\tn\nvfre "\\N_LP]/, Str::Escape
        rule %r/\\(?:x[0-9A-Fa-f]{2}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,
          Str::Escape
        rule %r/[^ \t\n\r\f\v"\\]+/, Str
      end

      state :plain_scalar_in_block_context_new_line do
        rule %r/^[ ]+\n/, Text
        rule %r/\n+/m, Text
        rule %r/^(?=---|\.\.\.)/ do
          pop! 3
        end

        # dedent detection
        rule %r/^[ ]*/ do |m|
          token Text
          pop!

          indent_size = m[0].size

          # dedent = end of scalar
          if indent_size <= self.indent
            pop!
            save_indent(m[0])
            push :indentation
          end
        end
      end

      state :plain_scalar_in_block_context do
        # the : indicator ends a scalar
        rule %r/[ ]*(?=:[ \n]|:$)/, Text, :pop!
        rule %r/[ ]*:\S+/, Str
        rule %r/[ ]+(?=#)/, Text, :pop!
        rule %r/[ ]+$/, Text
        # check for new documents or dedents at the new line
        rule %r/\n+/ do
          token Text
          push :plain_scalar_in_block_context_new_line
        end

        rule %r/[ ]+/, Str
        rule %r((true|false|null)\b), Keyword::Constant
        rule %r/\d+(?:\.\d+)?(?=(\r?\n)| +#)/, Literal::Number, :pop!

        # regular non-whitespace characters
        rule %r/[^\s:]+/, Str
      end

      state :plain_scalar_in_flow_context do
        rule %r/[ ]*(?=[,:?\[\]{}])/, Text, :pop!
        rule %r/[ ]+(?=#)/, Text, :pop!
        rule %r/^[ ]+/, Text
        rule %r/[ ]+$/, Text
        rule %r/\n+/, Text
        rule %r/[ ]+/, Name::Variable
        rule %r/[^\s,:?\[\]{}]+/, Name::Variable
      end

      state :yaml_directive do
        rule %r/([ ]+)(\d+\.\d+)/ do
          groups Text, Num
          goto :ignored_line
        end
      end

      state :tag_directive do
        rule %r(
          ([ ]+)(!|![\w-]*!) # prefix
          ([ ]+)(!|!?[\w;/?:@&=+$,.!~*'()\[\]%-]+) # tag handle
        )x do
          groups Text, Keyword::Type, Text, Keyword::Type
          goto :ignored_line
        end
      end
    end
  end
end
