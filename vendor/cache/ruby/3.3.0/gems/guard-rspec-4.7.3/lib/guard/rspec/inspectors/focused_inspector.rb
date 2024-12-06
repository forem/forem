require "guard/rspec/inspectors/base_inspector.rb"

module Guard
  class RSpec < Plugin
    module Inspectors
      # Inspector that focuses on set of paths if any of them is failing.
      # Returns only that set of paths on all future calls to #paths
      # until they all pass
      class FocusedInspector < BaseInspector
        attr_accessor :focused_locations

        def initialize(options = {})
          super
          @focused_locations = []
        end

        def paths(paths)
          if focused_locations.any?
            focused_locations
          else
            _clean(paths)
          end
        end

        def failed(locations)
          if locations.empty?
            @focused_locations = []
          elsif focused_locations.empty?
            @focused_locations = locations
          end
        end

        def reload
          @focused_locations = []
        end
      end
    end
  end
end
