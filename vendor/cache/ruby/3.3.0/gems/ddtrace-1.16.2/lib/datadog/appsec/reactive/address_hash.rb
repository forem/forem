# frozen_string_literal: true

module Datadog
  module AppSec
    module Reactive
      # AddressHash for Reactive Engine
      class AddressHash < Hash
        def self.new(*arguments, &block)
          super { |h, k| h[k] = [] }
        end

        def addresses
          keys.flatten
        end

        def with(address)
          keys.select { |k| k.include?(address) }
        end
      end
    end
  end
end
