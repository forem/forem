# frozen_string_literal: true

module Solargraph
  module Convention
    class Gemfile < Base
      def local source_map
        return EMPTY_ENVIRON unless File.basename(source_map.filename) == 'Gemfile'
        @environ ||= Environ.new(
          requires: ['bundler'],
          domains: ['Bundler::Dsl']
        )
      end
    end
  end
end
