# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    class SQF < RegexLexer
      tag "sqf"
      filenames "*.sqf"

      title "SQF"
      desc "Status Quo Function, a Real Virtuality engine scripting language"

      def self.wordoperators
        @wordoperators ||= Set.new %w(
          and or not
        )
      end

      def self.initializers
        @initializers ||= Set.new %w(
          private param params
        )
      end

      def self.controlflow
        @controlflow ||= Set.new %w(
          if then else exitwith switch do case default while for from to step
          foreach
        )
      end

      def self.constants
        @constants ||= Set.new %w(
          true false player confignull controlnull displaynull grpnull
          locationnull netobjnull objnull scriptnull tasknull teammembernull
        )
      end

      def self.namespaces
        @namespaces ||= Set.new %w(
          currentnamespace missionnamespace parsingnamespace profilenamespace
          uinamespace
        )
      end

      def self.diag_commands
        @diag_commands ||= Set.new %w(
          diag_activemissionfsms diag_activesqfscripts diag_activesqsscripts
          diag_activescripts diag_captureframe diag_captureframetofile
          diag_captureslowframe diag_codeperformance diag_drawmode diag_enable
          diag_enabled diag_fps diag_fpsmin diag_frameno diag_lightnewload
          diag_list diag_log diag_logslowframe diag_mergeconfigfile
          diag_recordturretlimits diag_setlightnew diag_ticktime diag_toggle
        )
      end

      def self.commands
        Kernel::load File.join(Lexers::BASE_DIR, "sqf/keywords.rb")
        commands
      end

      state :root do
        # Whitespace
        rule %r"\s+", Text

        # Preprocessor instructions
        rule %r"/\*.*?\*/"m, Comment::Multiline
        rule %r"//.*", Comment::Single
        rule %r"#(define|undef|if(n)?def|else|endif|include)", Comment::Preproc
        rule %r"\\\r?\n", Comment::Preproc
        rule %r"__(EVAL|EXEC|LINE__|FILE__)", Name::Builtin

        # Literals
        rule %r"\".*?\"", Literal::String
        rule %r"'.*?'", Literal::String
        rule %r"(\$|0x)[0-9a-fA-F]+", Literal::Number::Hex
        rule %r"[0-9]+(\.)?(e[0-9]+)?", Literal::Number::Float

        # Symbols
        rule %r"[\!\%\&\*\+\-\/\<\=\>\^\|\#]", Operator
        rule %r"[\(\)\{\}\[\]\,\:\;]", Punctuation

        # Identifiers (variables and functions)
        rule %r"[a-zA-Z0-9_]+" do |m|
          name = m[0].downcase
          if self.class.wordoperators.include? name
            token Operator::Word
          elsif self.class.initializers.include? name
            token Keyword::Declaration
          elsif self.class.controlflow.include? name
            token Keyword::Reserved
          elsif self.class.constants.include? name
            token Keyword::Constant
          elsif self.class.namespaces.include? name
            token Keyword::Namespace
          elsif self.class.diag_commands.include? name
            token Name::Function
          elsif self.class.commands.include? name
            token Name::Function
          elsif %r"_.+" =~ name
            token Name::Variable
          else
            token Name::Variable::Global
          end
        end
      end
    end
  end
end
