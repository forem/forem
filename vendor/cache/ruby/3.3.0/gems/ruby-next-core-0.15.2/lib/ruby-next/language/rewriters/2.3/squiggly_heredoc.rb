# frozen_string_literal: true

module RubyNext
  module Language
    module Rewriters
      class SquigglyHeredoc < Base
        NAME = "squiggly-heredoc"
        SYNTAX_PROBE = "txt = <<~TXT\n  bla\n      TXT"
        MIN_SUPPORTED_VERSION = Gem::Version.new("2.3.0")

        def on_str(node)
          node = super(node) if defined?(super_method)
          return node unless node.loc.respond_to?(:heredoc_body) && node.loc.expression.source.include?("<<~")

          context.track! self

          replace(node.loc.expression, node.loc.expression.source.tr("~", "-"))

          heredoc_loc = node.loc.heredoc_body.join(node.loc.heredoc_end)
          heredoc_source, heredoc_end = heredoc_loc.source.split(/\n([^\n]+)\z/)

          indent = heredoc_source.lines.map { |line| line.match(/^\s*/)[0].size }.min

          new_source = heredoc_source.gsub!(%r{^\s{#{indent}}}, "")

          replace(heredoc_loc, [new_source, heredoc_end].join("\n"))

          node
        end

        alias on_dstr on_str
        alias on_xstr on_str
      end
    end
  end
end
