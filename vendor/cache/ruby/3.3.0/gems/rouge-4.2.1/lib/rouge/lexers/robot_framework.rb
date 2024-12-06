# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class RobotFramework < RegexLexer
      tag 'robot_framework'
      aliases 'robot', 'robot-framework'

      title "Robot Framework"
      desc 'Robot Framework is a generic open source automation testing framework (robotframework.org)'

      filenames '*.robot'
      mimetypes 'text/x-robot'

      def initialize(opts = {})
        super(opts)
        @col = 0
        @next = nil
        @is_template = false
      end

      def self.settings_with_keywords
        @settings_with_keywords ||= Set.new [
          "library", "resource", "setup", "teardown", "template", "suite setup",
          "suite teardown", "task setup", "task teardown", "task template",
          "test setup", "test teardown", "test template", "variables"
        ]
      end
      
      def self.settings_with_args
        @settings_with_args ||= Set.new [
          "arguments", "default tags", "documentation", "force tags",
          "metadata", "return", "tags", "timeout", "task timeout",
          "test timeout"
        ]
      end

      id = %r/(?:\\|[^|$@&% \t\n])+(?: (?:\\.|[^|$@&% \t\n])+)*/
      bdd = %r/(?:Given|When|Then|And|But) /i
      sep = %r/ +\| +|[ ]{2,}|\t+/

      start do
        push :prior_text
      end

      state :prior_text do
        rule %r/^[^*].*/, Text
        rule(//) { pop! }
      end

      # Mixins

      state :whitespace do
        rule %r/\s+/, Text::Whitespace
      end

      state :section_include do
        mixin :end_section
        mixin :sep
        mixin :newline
      end

      state :end_section do
        rule(/(?=^(?:\| )?\*)/) { pop! }
      end

      state :return do
        rule(//) { pop! }
      end

      state :sep do
        rule %r/\| /, Text::Whitespace

        rule sep do
          token Text::Whitespace
          @col = @col + 1
          if @next
            push @next
          elsif @is_template
            push :args
          elsif @col == 1
            @next = :keyword
            push :keyword
          else
            push :args
          end
          push :cell_start
        end

        rule %r/\.\.\. */ do
          token Text::Whitespace
          @col = @col + 1
          push :args
        end
        
        rule %r/ ?\|/, Text::Whitespace
      end

      state :newline do
        rule %r/\n/ do
          token Text::Whitespace
          @col = 0
          @next = nil
          push :cell_start
        end
      end

      # States

      state :root do
        mixin :whitespace

        rule %r/^(?:\| )?\*[* ]*([A-Z]+(?: [A-Z]+)?).*/i do |m|
          token Generic::Heading, m[0]
          case m[1].chomp("s").downcase
          when "setting" then push :section_settings
          when "test case" then push :section_tests
          when "task" then push :section_tasks
          when "keyword" then push :section_keywords
          when "variable" then push :section_variables
          end
        end
      end

      state :section_settings do
        mixin :section_include

        rule %r/([A-Z]+(?: [A-Z]+)?)(:?)/i do |m|
          match = m[1].downcase
          @next = if self.class.settings_with_keywords.include? match
                    :keyword
                  elsif self.class.settings_with_args.include? match
                    :args
                  end
          groups Name::Builtin::Pseudo, Punctuation
        end
      end

      state :section_tests do
        mixin :section_include
        
        rule %r/[$@&%{}]+/, Name::Label
        rule %r/( )(?![ |])/, Name::Label

        rule id do
          @is_template = false
          token Name::Label
        end
      end

      state :section_tasks do
        mixin :section_tests
      end

      state :section_keywords do
        mixin :section_include
  
        rule %r/[$@&%]\{/ do
          token Name::Variable
          push :var
        end
        
        rule %r/[$@&%{}]+/, Name::Label
        rule %r/( )(?![ |])/, Name::Label
        
        rule id, Name::Label
      end

      state :section_variables do
        mixin :section_include

        rule %r/[$@&%]\{/ do
          token Name::Variable
          @next = :args
          push :var
        end
      end

      state :cell_start do
        rule %r/#.*/, Comment
        mixin :return
      end

      state :keyword do
        rule %r/(\[)([A-Z]+(?: [A-Z]+)?)(\])/i do |m|
          groups Punctuation, Name::Builtin::Pseudo, Punctuation
          
          match = m[2].downcase
          @is_template = true if match == "template"
          if self.class.settings_with_keywords.include? match
            @next = :keyword
          elsif self.class.settings_with_args.include? match
            @next = :args
          end

          pop!
        end

        rule %r/[$@&%]\{/ do
          token Name::Variable
          @next = :keyword unless @next.nil?
          push :var
        end

        rule %r/FOR/i do
          token Name::Function
          @next = :keyword unless @next.nil?
        end

        rule %r/( )(?![ |])/, Name::Function

        rule bdd, Name::Builtin
        rule id do
          token Name::Function
          @next = nil
        end

        mixin :return
      end

      state :args do
        rule %r/[$@&%]\{/ do
          token Name::Variable
          @next = :keyword unless @next.nil?
          push :var
        end

        rule %r/[$@&%]+/, Str
        rule %r/( )(?![ |])/, Str
        rule id, Str
        
        mixin :return
      end

      state :var do
        rule %r/(\})( )(=)/ do
          groups Name::Variable, Text::Whitespace, Punctuation
          pop!
        end
        rule %r/[$@&%]\{/, Name::Variable, :var
        rule %r/[{\[]/, Name::Variable, :var
        rule %r/[}\]]/, Name::Variable, :pop!
        rule %r/[^$@&%{}\[\]]+/, Name::Variable
        rule %r/\}\[/, Name::Variable
      end
    end
  end
end
