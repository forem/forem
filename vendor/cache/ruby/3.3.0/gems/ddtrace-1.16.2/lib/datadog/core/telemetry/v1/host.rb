# frozen_string_literal: true

require_relative '../../utils/hash'

module Datadog
  module Core
    module Telemetry
      module V1
        # Describes attributes for host object
        class Host
          using Core::Utils::Hash::Refinement

          attr_reader \
            :container_id,
            :hostname,
            :kernel_name,
            :kernel_release,
            :kernel_version,
            :os_version,
            :os

          # @param container_id [String] Docker container ID
          # @param hostname [String] uname -n
          # @param kernel_name [String] uname -s
          # @param kernel_release [String] uname -r
          # @param kernel_version [String] uname -v
          # @param os [String] uname -o
          # @param os_version [String] Version of OS running
          def initialize(
            container_id: nil, hostname: nil, kernel_name: nil, kernel_release: nil, kernel_version: nil,
            os_version: nil, os: nil
          )
            @container_id = container_id
            @hostname = hostname
            @kernel_name = kernel_name
            @kernel_release = kernel_release
            @kernel_version = kernel_version
            @os = os
            @os_version = os_version
          end

          def to_h
            hash = {
              container_id: @container_id,
              hostname: @hostname,
              kernel_name: @kernel_name,
              kernel_release: @kernel_release,
              kernel_version: @kernel_version,
              os: @os,
              os_version: @os_version,
            }
            hash.compact!
            hash
          end
        end
      end
    end
  end
end
