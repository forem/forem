# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Groovy < RegexLexer
      title "Groovy"
      desc 'The Groovy programming language (http://www.groovy-lang.org/)'
      tag 'groovy'
      filenames '*.groovy', 'Jenkinsfile', '*.Jenkinsfile'
      mimetypes 'text/x-groovy'

      def self.detect?(text)
        return true if text.shebang?(/groovy/)
      end

      def self.keywords
        @keywords ||= Set.new %w(
          assert break case catch continue default do else finally for
          if goto instanceof new return switch this throw try while in as
        )
      end

      def self.declarations
        @declarations ||= Set.new %w(
          abstract const extends final implements native private
          protected public static strictfp super synchronized throws
          transient volatile
        )
      end

      def self.types
        @types ||= Set.new %w(
          def var boolean byte char double float int long short void
        )
      end

      def self.constants
        @constants ||= Set.new %w(true false null)
      end

      state :root do
        rule %r(^
          (\s*(?:\w[\w.\[\]]*\s+)+?) # return arguments
          (\w\w*) # method name
          (\s*) (\() # signature start
        )x do |m|
          delegate self.clone, m[1]
          token Name::Function, m[2]
          token Text, m[3]
          token Operator, m[4]
        end

        # whitespace
        rule %r/[^\S\n]+/, Text
        rule %r(//.*?$), Comment::Single
        rule %r(/[*].*?[*]/)m, Comment::Multiline
        rule %r/@\w[\w.]*/, Name::Decorator
        rule %r/(class|interface|trait|enum|record)\b/,  Keyword::Declaration, :class
        rule %r/package\b/, Keyword::Namespace, :import
        rule %r/import\b/, Keyword::Namespace, :import

        # TODO: highlight backslash escapes
        rule %r/""".*?"""/m, Str::Double
        rule %r/'''.*?'''/m, Str::Single

        rule %r/"(\\.|\\\n|.)*?"/, Str::Double
        rule %r/'(\\.|\\\n|.)*?'/, Str::Single
        rule %r(\$/(\$.|.)*?/\$)m, Str
        rule %r(/(\\.|\\\n|.)*?/), Str
        rule %r/'\\.'|'[^\\]'|'\\u[0-9a-f]{4}'/, Str::Char
        rule %r/(\.)([a-zA-Z_][a-zA-Z0-9_]*)/ do
          groups Operator, Name::Attribute
        end

        rule %r/[a-zA-Z_][a-zA-Z0-9_]*:/, Name::Label
        rule %r/[a-zA-Z_\$][a-zA-Z0-9_]*/ do |m|
          if self.class.keywords.include? m[0]
            token Keyword
          elsif self.class.declarations.include? m[0]
            token Keyword::Declaration
          elsif self.class.types.include? m[0]
            token Keyword::Type
          elsif self.class.constants.include? m[0]
            token Keyword::Constant
          else
            token Name
          end
        end

        rule %r([~^*!%&\[\](){}<>\|+=:;,./?-]), Operator

        # numbers
        rule %r/\d+\.\d+([eE]\d+)?[fd]?/, Num::Float
        rule %r/0x[0-9a-f]+/, Num::Hex
        rule %r/[0-9]+L?/, Num::Integer
        rule %r/\n/, Text
      end

      state :class do
        rule %r/\s+/, Text
        rule %r/\w\w*/, Name::Class, :pop!
      end

      state :import do
        rule %r/\s+/, Text
        rule %r/[\w.]+[*]?/, Name::Namespace, :pop!
      end
    end
  end
end
