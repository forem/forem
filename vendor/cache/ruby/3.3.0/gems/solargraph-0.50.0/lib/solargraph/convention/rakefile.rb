# frozen_string_literal: true

module Solargraph
  module Convention
    class Rakefile < Base
      def local source_map
        basename = File.basename(source_map.filename)
        return EMPTY_ENVIRON unless basename.end_with?('.rake') || basename == 'Rakefile'

        @environ ||= Environ.new(
          requires: ['rake'],
          domains: ['Rake::DSL']
        )
      end
    end
  end
end
