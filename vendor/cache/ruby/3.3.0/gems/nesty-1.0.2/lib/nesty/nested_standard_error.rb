module Nesty
  class NestedStandardError < StandardError
    include NestedError
  end
end
