require 'nenv/environment'
module Nenv
  class AutoEnvironment < Nenv::Environment
    def method_missing(meth, *args)
      create_method(meth) unless respond_to?(meth)
      send(meth, *args)
    end
  end
end
