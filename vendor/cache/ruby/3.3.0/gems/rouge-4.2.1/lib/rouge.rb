# -*- coding: utf-8 -*- #
# frozen_string_literal: true

# stdlib
require 'pathname'

# The containing module for Rouge
module Rouge
  # cache value in a constant since `__dir__` allocates a new string
  # on every call.
  LIB_DIR = __dir__.freeze

  class << self
    def reload!
      Object::send :remove_const, :Rouge
      Kernel::load __FILE__
    end

    # Highlight some text with a given lexer and formatter.
    #
    # @example
    #   Rouge.highlight('@foo = 1', 'ruby', 'html')
    #   Rouge.highlight('var foo = 1;', 'js', 'terminal256')
    #
    #   # streaming - chunks become available as they are lexed
    #   Rouge.highlight(large_string, 'ruby', 'html') do |chunk|
    #     $stdout.print chunk
    #   end
    def highlight(text, lexer, formatter, &b)
      lexer = Lexer.find(lexer) unless lexer.respond_to? :lex
      raise "unknown lexer #{lexer}" unless lexer

      formatter = Formatter.find(formatter) unless formatter.respond_to? :format
      raise "unknown formatter #{formatter}" unless formatter

      formatter.format(lexer.lex(text), &b)
    end

    # Load a file relative to the `lib/rouge` path.
    #
    # @api private
    def load_file(path)
      Kernel::load File.join(LIB_DIR, "rouge/#{path}.rb")
    end

    # Load the lexers in the `lib/rouge/lexers` directory.
    #
    # @api private
    def load_lexers
      lexer_dir = Pathname.new(LIB_DIR) / "rouge/lexers"
      Pathname.glob(lexer_dir / '*.rb').each do |f|
        Lexers.load_lexer(f.relative_path_from(lexer_dir))
      end
    end
  end
end

Rouge.load_file 'version'
Rouge.load_file 'util'
Rouge.load_file 'text_analyzer'
Rouge.load_file 'token'

Rouge.load_file 'lexer'
Rouge.load_file 'regex_lexer'
Rouge.load_file 'template_lexer'

Rouge.load_lexers

Rouge.load_file 'guesser'
Rouge.load_file 'guessers/util'
Rouge.load_file 'guessers/glob_mapping'
Rouge.load_file 'guessers/modeline'
Rouge.load_file 'guessers/filename'
Rouge.load_file 'guessers/mimetype'
Rouge.load_file 'guessers/source'
Rouge.load_file 'guessers/disambiguation'

Rouge.load_file 'formatter'
Rouge.load_file 'formatters/html'
Rouge.load_file 'formatters/html_table'
Rouge.load_file 'formatters/html_pygments'
Rouge.load_file 'formatters/html_legacy'
Rouge.load_file 'formatters/html_linewise'
Rouge.load_file 'formatters/html_line_highlighter'
Rouge.load_file 'formatters/html_line_table'
Rouge.load_file 'formatters/html_inline'
Rouge.load_file 'formatters/terminal256'
Rouge.load_file 'formatters/terminal_truecolor'
Rouge.load_file 'formatters/tex'
Rouge.load_file 'formatters/null'

Rouge.load_file 'theme'
Rouge.load_file 'tex_theme_renderer'
Rouge.load_file 'themes/thankful_eyes'
Rouge.load_file 'themes/colorful'
Rouge.load_file 'themes/base16'
Rouge.load_file 'themes/github'
Rouge.load_file 'themes/igor_pro'
Rouge.load_file 'themes/monokai'
Rouge.load_file 'themes/molokai'
Rouge.load_file 'themes/monokai_sublime'
Rouge.load_file 'themes/gruvbox'
Rouge.load_file 'themes/tulip'
Rouge.load_file 'themes/pastie'
Rouge.load_file 'themes/bw'
Rouge.load_file 'themes/magritte'
