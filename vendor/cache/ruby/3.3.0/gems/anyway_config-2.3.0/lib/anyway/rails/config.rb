# frozen_string_literal: true

require "active_support/core_ext/hash/indifferent_access"

module Anyway
  module Rails
    # Enhance config to be more Railsy-like:
    # – accept hashes with indeferent access
    # - load data from secrets
    # - recognize Rails env when loading from YML
    module Config
      module ClassMethods
        # Make defaults to be a Hash with indifferent access
        def new_empty_config
          {}.with_indifferent_access
        end
      end
    end
  end
end

Anyway::Config.prepend Anyway::Rails::Config
Anyway::Config.singleton_class.prepend Anyway::Rails::Config::ClassMethods
