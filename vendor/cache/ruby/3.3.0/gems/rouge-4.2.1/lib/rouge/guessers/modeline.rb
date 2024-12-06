# frozen_string_literal: true

module Rouge
  module Guessers
    class Modeline < Guesser
      include Util

      # [jneen] regexen stolen from linguist
      EMACS_MODELINE = /-\*-\s*(?:(?!mode)[\w-]+\s*:\s*(?:[\w+-]+)\s*;?\s*)*(?:mode\s*:)?\s*([\w+-]+)\s*(?:;\s*(?!mode)[\w-]+\s*:\s*[\w+-]+\s*)*;?\s*-\*-/i

      # First form vim modeline
      # [text]{white}{vi:|vim:|ex:}[white]{options}
      # ex: 'vim: syntax=ruby'
      VIM_MODELINE_1 = /(?:vim|vi|ex):\s*(?:ft|filetype|syntax)=(\w+)\s?/i

      # Second form vim modeline (compatible with some versions of Vi)
      # [text]{white}{vi:|vim:|Vim:|ex:}[white]se[t] {options}:[text]
      # ex: 'vim set syntax=ruby:'
      VIM_MODELINE_2 = /(?:vim|vi|Vim|ex):\s*se(?:t)?.*\s(?:ft|filetype|syntax)=(\w+)\s?.*:/i

      MODELINES = [EMACS_MODELINE, VIM_MODELINE_1, VIM_MODELINE_2]

      def initialize(source, opts={})
        @source = source
        @lines = opts[:lines] || 5
      end

      def filter(lexers)
        # don't bother reading the stream if we've already decided
        return lexers if lexers.size == 1

        source_text = get_source(@source)

        lines = source_text.split(/\n/)

        search_space = (lines.first(@lines) + lines.last(@lines)).join("\n")

        matches = MODELINES.map { |re| re.match(search_space) }.compact
        return lexers unless matches.any?

        match_set = Set.new(matches.map { |m| m[1] })
        lexers.select { |l| match_set.include?(l.tag) || l.aliases.any? { |a| match_set.include?(a) } }
      end
    end
  end
end
