# frozen_string_literal: true

require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for products object
        class Product
          using Core::Utils::Hash::Refinement

          attr_reader \
            :appsec,
            :profiler

          # @param appsec [Telemetry::V1::AppSec] Holds custom information about the appsec product
          # @param profiler [Telemetry::V1::Profiler] Holds custom information about the profiler product
          def initialize(appsec: nil, profiler: nil)
            @appsec = appsec
            @profiler = profiler
          end

          def to_h
            hash = {
              appsec: @appsec,
              profiler: @profiler
            }
            hash.compact!
            hash
          end
        end
      end
    end
  end
end
