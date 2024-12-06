# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `str`, `dstr`, and `xstr` nodes. This will be used
    # in place of a plain node when the builder constructs the AST, making
    # its methods available to all `str` nodes within RuboCop.
    class StrNode < Node
      include BasicLiteralNode

      def character_literal?
        loc.respond_to?(:begin) && loc.begin && loc.begin.is?('?')
      end

      def heredoc?
        loc.is_a?(Parser::Source::Map::Heredoc)
      end
    end
  end
end
