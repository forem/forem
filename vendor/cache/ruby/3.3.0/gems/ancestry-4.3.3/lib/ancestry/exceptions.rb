module Ancestry
  class AncestryException < RuntimeError
  end

  class AncestryIntegrityException < AncestryException
  end
end