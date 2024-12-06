module Solargraph
  class Source
    class Chain
      class QCall < Call
        def nullable?
          true
        end
      end
    end
  end
end
