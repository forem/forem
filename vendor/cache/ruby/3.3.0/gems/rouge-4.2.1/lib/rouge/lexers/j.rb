# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class J < RegexLexer
      title 'J'
      desc "The J programming language (jsoftware.com)"
      tag 'j'
      filenames '*.ijs', '*.ijt'

      # For J-specific terms we use, see:
      #   https://code.jsoftware.com/wiki/Vocabulary/AET
      #   https://code.jsoftware.com/wiki/Vocabulary/Glossary

      # https://code.jsoftware.com/wiki/Vocabulary/PartsOfSpeech
      def self.token_map
        @token_map ||= {
          noun: Keyword::Constant,
          verb: Name::Function,
          modifier: Operator,
          name: Name,
          param: Name::Builtin::Pseudo,
          other: Punctuation,
          nil => Error,
        }
      end

      # https://code.jsoftware.com/wiki/NuVoc
      def self.inflection_list
        @inflection_list ||= ['', '.', ':', '..', '.:', ':.', '::']
      end

      def self.primitive_table
        @primitive_table ||= Hash.new([:name]).tap do |h|
          {
            '()' => [:other],
            '=' => [:verb, :other, :other],
            '<>+-*%$|,#' => [:verb, :verb, :verb],
            '^' => [:verb, :verb, :modifier],
            '~"' => [:modifier, :verb, :verb],
            '.:@' => [:modifier, :modifier, :modifier],
            ';' => [:verb, :modifier, :verb],
            '!' => [:verb, :modifier, :modifier],
            '/\\' => [:modifier, :modifier, :verb],
            '[' => [:verb, nil, :verb],
            ']' => [:verb],
            '{' => [:verb, :verb, :verb, nil, nil, nil, :verb],
            '}' => [:modifier, :verb, :verb, nil, nil, nil, :modifier],
            '`' => [:modifier, nil, :modifier],
            '&' => [:modifier, :modifier, :modifier, nil, :modifier],
            '?' => [:verb, :verb],
            'a' => [:name, :noun, :noun],
            'ACeEIjorv' => [:name, :verb],
            'bdfHMT' => [:name, :modifier],
            'Dt' => [:name, :modifier, :modifier],
            'F' => [:name, :modifier, :modifier, :modifier, :modifier,
                    :modifier, :modifier],
            'iu' => [:name, :verb, :verb],
            'L' => [:name, :verb, :modifier],
            'mny' => [:param],
            'p' => [:name, :verb, :verb, :verb],
            'qsZ' => [:name, nil, :verb],
            'S' => [:name, nil, :modifier],
            'u' => [:param, :verb, :verb],
            'v' => [:param, :verb],
            'x' => [:param, nil, :verb],
          }.each {|k, v| k.each_char {|c| h[c] = v } }
        end
      end

      def self.primitive(char, inflection)
        i = inflection_list.index(inflection) or return Error
        token_map[primitive_table[char][i]]
      end

      def self.control_words
        @control_words ||= Set.new %w(
          assert break case catch catchd catcht continue do else elseif end
          fcase for if return select throw try while whilst
        )
      end

      def self.control_words_id
        @control_words_id ||= Set.new %w(for goto label)
      end

      state :expr do
        rule %r/\s+/, Text

        rule %r'([!-&(-/:-@\[-^`{-~]|[A-Za-z]\b)([.:]*)' do |m|
          token J.primitive(m[1], m[2])
        end

        rule %r/(?:\d|_\d?):([.:]*)/ do |m|
          token m[1].empty? ? J.token_map[:verb] : Error
        end

        rule %r/[\d_][\w.]*([.:]*)/ do |m|
          token m[1].empty? ? Num : Error
        end

        rule %r/'/, Str::Single, :str

        rule %r/NB\.(?![.:]).*/, Comment::Single

        rule %r/([A-Za-z]\w*)([.:]*)/ do |m|
          if m[2] == '.'
            word, sep, id = m[1].partition '_'
            list = if sep.empty?
              J.control_words
            elsif not id.empty?
              J.control_words_id
            end
            if list and list.include? word
              token Keyword, word + sep
              token((word == 'for' ? Name : Name::Label), id)
              token Keyword, m[2]
            else
              token Error
            end
          else
            token m[2].empty? ? Name : Error
          end
        end
      end

      state :str do
        rule %r/''/, Str::Escape
        rule %r/[^'\n]+/, Str::Single
        rule %r/'|$/, Str::Single, :pop!
      end

      start do
        @note_next = false
      end

      state :root do
        rule %r/\n/ do
          token Text
          if @note_next
            push :note
            @note_next = false
          end
        end

        # https://code.jsoftware.com/wiki/Vocabulary/com
        # https://code.jsoftware.com/wiki/Vocabulary/NounExplicitDefinition
        rule %r/
          ([0-4]|13|adverb|conjunction|dyad|monad|noun|verb)([\ \t]+)
          (def(?:ine)?\b|:)(?![.:])([\ \t]*)
        /x do |m|
          groups Keyword::Pseudo, Text, Keyword::Pseudo, Text
          @def_body = (m[1] == '0' || m[1] == 'noun') ? :noun : :code
          if m[3] == 'define'
            # stack: [:root]
            #    or  [:root, ..., :def_next]
            pop! if stack.size > 1
            push @def_body
            push :def_next  # [:root, ..., @def_body, :def_next]
          else
            push :expl_def
          end
        end

        rule %r/^([ \t]*)(Note\b(?![.:]))([ \t\r]*)(?!=[.:]|$)/ do
          groups Text, Name, Text
          @note_next = true
        end

        rule %r/[mnuvxy]\b(?![.:])/, Name
        mixin :expr
      end

      state :def_next do
        rule %r/\n/, Text, :pop!
        mixin :root
      end

      state :expl_def do
        rule %r/0\b(?![.:])/ do
          token Keyword::Pseudo
          # stack: [:root, :expl_def]
          #    or  [:root, ..., :def_next, :expl_def]
          pop! if stack.size > 2
          goto @def_body
          push :def_next  # [:root, ..., @def_body, :def_next]
        end
        rule %r/'/ do
          if @def_body == :noun
            token Str::Single
            goto :str
          else
            token Punctuation
            goto :q_expr
          end
        end
        rule(//) { pop! }
      end

      # `q_expr` lexes the content of a string literal which is a part of an
      # explicit definition.
      # e.g. dyad def 'x + y'
      state :q_expr do
        rule %r/''/, Str::Single, :q_str
        rule %r/'|$/, Punctuation, :pop!
        rule %r/NB\.(?![.:])([^'\n]|'')*/, Comment::Single
        mixin :expr
      end

      state :q_str do
        rule %r/''''/, Str::Escape
        rule %r/[^'\n]+/, Str::Single
        rule %r/''/, Str::Single, :pop!
        rule(/'|$/) { token Punctuation; pop! 2 }
      end

      state :note do
        mixin :delimiter
        rule %r/.+\n?/, Comment::Multiline
      end

      state :noun do
        mixin :delimiter
        rule %r/.+\n?/, Str::Heredoc
      end

      state :code do
        mixin :delimiter
        rule %r/^([ \t]*)(:)([ \t\r]*)$/ do
          groups Text, Punctuation, Text
        end
        mixin :expr
      end

      state :delimiter do
        rule %r/^([ \t]*)(\))([ \t\r]*$\n?)/ do
          groups Text, Punctuation, Text
          pop!
        end
      end
    end
  end
end
