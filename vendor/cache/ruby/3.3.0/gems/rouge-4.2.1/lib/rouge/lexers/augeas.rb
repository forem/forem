# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Augeas < RegexLexer
      title "Augeas"
      desc "The Augeas programming language (augeas.net)"

      tag 'augeas'
      aliases 'aug'
      filenames '*.aug'
      mimetypes 'text/x-augeas'

      def self.reserved
        @reserved ||= Set.new %w(
          _ let del store value counter seq key label autoload incl excl
          transform test get put in after set clear insa insb print_string
          print_regexp print_endline print_tree lens_ctype lens_atype
          lens_ktype lens_vtype lens_format_atype regexp_match
        )
      end

      state :basic do
        rule %r/\s+/m, Text
        rule %r/\(\*/, Comment::Multiline, :comment
      end

      state :comment do
        rule %r/\*\)/, Comment::Multiline, :pop!
        rule %r/\(\*/, Comment::Multiline, :comment
        rule %r/[^*)]+/, Comment::Multiline
        rule %r/[*)]/, Comment::Multiline
      end

      state :root do
        mixin :basic

        rule %r/(:)(\w\w*)/ do
          groups Punctuation, Keyword::Type
        end

        rule %r/\w[\w']*/ do |m|
          name = m[0]
          if name == "module"
            token Keyword::Reserved
            push :module
          elsif self.class.reserved.include? name
            token Keyword::Reserved
          elsif name =~ /\A[A-Z]/
            token Keyword::Namespace
          else
            token Name
          end
        end

        rule %r/"/, Str, :string
        rule %r/\//, Str, :regexp

        rule %r([-*+.=?\|]+), Operator
        rule %r/[\[\](){}:;]/, Punctuation
      end

      state :module do
        rule %r/\s+/, Text
        rule %r/[A-Z][a-zA-Z0-9_.]*/, Name::Namespace, :pop!
      end

      state :regexp do
        rule %r/\//, Str::Regex, :pop!
        rule %r/[^\\\/]+/, Str::Regex
        rule %r/\\[\\\/]/, Str::Regex
        rule %r/\\/, Str::Regex
      end

      state :string do
        rule %r/"/, Str, :pop!
        rule %r/\\/, Str::Escape, :escape
        rule %r/[^\\"]+/, Str
      end

      state :escape do
        rule %r/[abfnrtv"'&\\]/, Str::Escape, :pop!
        rule %r/\^[\]\[A-Z@\^_]/, Str::Escape, :pop!
        rule %r/o[0-7]+/i, Str::Escape, :pop!
        rule %r/x[\da-f]+/i, Str::Escape, :pop!
        rule %r/\d+/, Str::Escape, :pop!
        rule %r/\s+/, Str::Escape, :pop!
        rule %r/./, Str, :pop!
      end
    end
  end
end
