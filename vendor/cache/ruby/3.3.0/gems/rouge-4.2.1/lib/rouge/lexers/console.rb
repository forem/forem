# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    # The {ConsoleLexer} class is intended to lex content that represents the
    # text that would display in a console/terminal. As distinct from the
    # {Shell} lexer, {ConsoleLexer} will try to parse out the prompt from each
    # line before passing the remainder of the line to the language lexer for
    # the shell (by default, the {Shell} lexer).
    #
    # The {ConsoleLexer} class accepts five options:
    # 1. **lang**: the shell language to lex (default: `shell`);
    # 2. **output**: the output language (default: `plaintext?token=Generic.Output`);
    # 3. **prompt**: comma-separated list of strings that indicate the end of a
    #    prompt (default: `$,#,>,;`);
    # 4. **comments**: whether to enable comments.
    # 5. **error**: comma-separated list of strings that indicate the start of an
    #    error message
    #
    # The comments option, if enabled, will lex lines that begin with a `#` as a
    # comment. Please note that this option will only work if the prompt is
    # either not manually specified or, if manually specified, does not include
    # the `#` character.
    #
    # Most Markdown lexers that recognise GitHub-Flavored Markdown syntax, will
    # pass the language string to Rouge as written in the original document.
    # This allows an end user to pass options to {ConsoleLexer} by passing them
    # as CGI-style parameters as in the example below.
    #
    # @example
    # <pre>Here's some regular text.
    #
    # ```console?comments=true
    # # This is a comment
    # $ cp foo bar
    # ```
    #
    # Some more regular text.</pre>
    class ConsoleLexer < Lexer
      tag 'console'
      aliases 'terminal', 'shell_session', 'shell-session'
      filenames '*.cap'
      desc 'A generic lexer for shell sessions. Accepts ?lang and ?output lexer options, a ?prompt option, ?comments to enable # comments, and ?error to handle error messages.'

      option :lang, 'the shell language to lex (default: shell)'
      option :output, 'the output language (default: plaintext?token=Generic.Output)'
      option :prompt, 'comma-separated list of strings that indicate the end of a prompt. (default: $,#,>,;)'
      option :comments, 'enable hash-comments at the start of a line - otherwise interpreted as a prompt. (default: false, implied by ?prompt not containing `#`)'
      option :error, 'comma-separated list of strings that indicate the start of an error message'

      def initialize(*)
        super
        @prompt = list_option(:prompt) { nil }
        @lang = lexer_option(:lang) { 'shell' }
        @output = lexer_option(:output) { PlainText.new(token: Generic::Output) }
        @comments = bool_option(:comments) { :guess }
        @error = list_option(:error) { nil }
      end

      # whether to allow comments. if manually specifying a prompt that isn't
      # simply "#", we flag this to on
      def allow_comments?
        case @comments
        when :guess
          @prompt && !@prompt.empty? && !end_chars.include?('#')
        else
          @comments
        end
      end

      def comment_regex
        /\A\s*?#/
      end

      def end_chars
        @end_chars ||= if @prompt.any?
          @prompt.reject { |c| c.empty? }
        elsif allow_comments?
          %w($ > ;)
        else
          %w($ # > ;)
        end
      end

      def error_regex
        @error_regex ||= if @error.any?
          /^(?:#{@error.map(&Regexp.method(:escape)).join('|')})/
        end
      end

      def lang_lexer
        @lang_lexer ||= case @lang
        when Lexer
          @lang
        when nil
          Shell.new(options)
        when Class
          @lang.new(options)
        when String
          Lexer.find(@lang).new(options)
        end
      end

      def line_regex
        /(.*?)(\n|$)/
      end

      def output_lexer
        @output_lexer ||= case @output
        when nil
          PlainText.new(token: Generic::Output)
        when Lexer
          @output
        when Class
          @output.new(options)
        when String
          Lexer.find(@output).new(options)
        end
      end

      def process_line(input, &output)
        input.scan(line_regex)

        # As a nicety, support the use of elisions in input text. A user can
        # write a line with only `<...>` or one or more `.` characters and
        # Rouge will treat it as a comment.
        if input[0] =~ /\A\s*(?:<[.]+>|[.]+)\s*\z/
          puts "console: matched snip #{input[0].inspect}" if @debug
          output_lexer.reset!
          lang_lexer.reset!

          yield Comment, input[0]
        elsif prompt_regex =~ input[0]
          puts "console: matched prompt #{input[0].inspect}" if @debug
          output_lexer.reset!

          yield Generic::Prompt, $&

          # make sure to take care of initial whitespace
          # before we pass to the lang lexer so it can determine where
          # the "real" beginning of the line is
          $' =~ /\A\s*/
          yield Text::Whitespace, $& unless $&.empty?

          lang_lexer.continue_lex($', &output)
        elsif comment_regex =~ input[0].strip
          puts "console: matched comment #{input[0].inspect}" if @debug
          output_lexer.reset!
          lang_lexer.reset!

          yield Comment, input[0]
        elsif error_regex =~ input[0]
          puts "console: matched error #{input[0].inspect}" if @debug
          output_lexer.reset!
          lang_lexer.reset!

          yield Generic::Error, input[0]
        else
          puts "console: matched output #{input[0].inspect}" if @debug
          lang_lexer.reset!

          output_lexer.continue_lex(input[0], &output)
        end
      end

      def prompt_prefix_regex
        if allow_comments?
          /[^<#]*?/m
        else
          /.*?/m
        end
      end

      def prompt_regex
        @prompt_regex ||= begin
          /^#{prompt_prefix_regex}(?:#{end_chars.map(&Regexp.method(:escape)).join('|')})/
        end
      end

      def stream_tokens(input, &output)
        input = StringScanner.new(input)
        lang_lexer.reset!
        output_lexer.reset!

        process_line(input, &output) while !input.eos?
      end
    end
  end
end
