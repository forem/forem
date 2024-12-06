# frozen_string_literal: true

module MemoryProfiler
  class StatHash < Hash
    include TopN
  end
end
