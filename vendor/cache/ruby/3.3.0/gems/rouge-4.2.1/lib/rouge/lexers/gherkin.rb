# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class Gherkin < RegexLexer
      tag 'gherkin'
      aliases 'cucumber', 'behat'

      title "Gherkin"
      desc 'A business-readable spec DSL (github.com/cucumber/cucumber/wiki/Gherkin)'

      filenames '*.feature'
      mimetypes 'text/x-gherkin'

      def self.detect?(text)
        return true if text.shebang? 'cucumber'
      end

      # self-modifying method that loads the keywords file
      def self.keywords
        Kernel::load File.join(Lexers::BASE_DIR, 'gherkin/keywords.rb')
        keywords
      end

      def self.step_regex
        # in Gherkin's config, keywords that end in < don't
        # need word boundaries at the ends - all others do.
        @step_regex ||= Regexp.new(
          keywords[:step].map do |w|
            if w.end_with? '<'
              Regexp.escape(w.chop)
            elsif w.end_with?(' ')
              Regexp.escape(w)
            else
              "#{Regexp.escape(w)}\\b"
            end
          end.join('|')
        )
      end

      rest_of_line = /.*?(?=[#\n])/

      state :basic do
        rule %r(#.*$), Comment
        rule %r/[ \r\t]+/, Text
      end

      state :root do
        mixin :basic
        rule %r(\n), Text
        rule %r(""".*?""")m, Str
        rule %r(@[^\s@]+), Name::Tag
        mixin :has_table
        mixin :has_examples
      end

      state :has_scenarios do
        rule %r((.*?)(:)) do |m|
          reset_stack

          keyword = m[1]
          keyword_tok = if self.class.keywords[:element].include? keyword
            push :description; Keyword::Namespace
          elsif self.class.keywords[:feature].include? keyword
            push :feature_description; Keyword::Declaration
          elsif self.class.keywords[:examples].include? keyword
            push :example_description; Name::Namespace
          else
            Error
          end

          groups keyword_tok, Punctuation
        end
      end

      state :has_examples do
        mixin :has_scenarios
        rule Gherkin.step_regex, Name::Function do
          token Name::Function
          reset_stack; push :step
        end
      end

      state :has_table do
        rule(/(?=[|])/) { push :table_header }
      end

      state :table_header do
        rule %r/[^|\s]+/, Name::Variable
        rule %r/\n/ do
          token Text
          goto :table
        end
        mixin :table
      end

      state :table do
        mixin :basic
        rule %r/\n/, Text, :table_bol
        rule %r/[|]/, Punctuation
        rule %r/[^|\s]+/, Name
      end

      state :table_bol do
        rule(/(?=\s*[^\s|])/) { reset_stack }
        rule(//) { pop! }
      end

      state :description do
        mixin :basic
        mixin :has_examples
        rule %r/\n/, Text
        rule rest_of_line, Text
      end

      state :feature_description do
        mixin :basic
        mixin :has_scenarios
        rule %r/\n/, Text
        rule rest_of_line, Text
      end

      state :example_description do
        mixin :basic
        mixin :has_table
        rule %r/\n/, Text
        rule rest_of_line, Text
      end

      state :step do
        mixin :basic
        rule %r/<.*?>/, Name::Variable
        rule %r/".*?"/, Str
        rule %r/\S[^\s<]*/, Text
        rule rest_of_line, Text, :pop!
      end
    end
  end
end
