require "guard/rspec/inspectors/base_inspector"

module Guard
  class RSpec < Plugin
    module Inspectors
      class SimpleInspector < BaseInspector
        def paths(paths)
          _clean(paths)
        end

        def failed(_locations)
          # Don't care
        end

        def reload
          # Nothing to reload
        end
      end
    end
  end
end
