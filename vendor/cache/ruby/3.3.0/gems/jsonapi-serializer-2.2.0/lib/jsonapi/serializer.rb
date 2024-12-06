require 'fast_jsonapi'

module JSONAPI
  module Serializer
    # TODO: Move and cleanup the old implementation...
    def self.included(base)
      base.class_eval do
        include FastJsonapi::ObjectSerializer
      end
    end
  end
end
