# frozen_string_literal: true

module Datadog
  module Tracing
    module Contrib
      # Contrib specific constants
      module Ext
        # @public_api
        module DB
          TAG_INSTANCE = 'db.instance'
          TAG_USER = 'db.user'
          TAG_SYSTEM = 'db.system'
          TAG_STATEMENT = 'db.statement'
          TAG_ROW_COUNT = 'db.row_count'
          PEER_SERVICE_SOURCES = Array[TAG_INSTANCE,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end

        module RPC
          TAG_SYSTEM = 'rpc.system'
          TAG_SERVICE = 'rpc.service'
          TAG_METHOD = 'rpc.method'
          PEER_SERVICE_SOURCES = Array[TAG_SERVICE,
            Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
          module GRPC
            TAG_STATUS_CODE = 'rpc.grpc.status_code'
            TAG_FULL_METHOD = 'rpc.grpc.full_method'
          end
        end

        module Messaging
          TAG_SYSTEM = 'messaging.system'
          PEER_SERVICE_SOURCES = Array[Tracing::Metadata::Ext::NET::TAG_DESTINATION_NAME,
            Tracing::Metadata::Ext::TAG_PEER_HOSTNAME,
            Tracing::Metadata::Ext::NET::TAG_TARGET_HOST,].freeze
        end

        module Metadata
          # Name of tag from which where peer.service information was extracted from
          TAG_PEER_SERVICE_SOURCE = '_dd.peer.service.source'

          # Value of tag from which peer.service value was remapped from
          TAG_PEER_SERVICE_REMAP = '_dd.peer.service.remapped_from'

          # Set equal to the global service when contrib span.service is overriden
          TAG_BASE_SERVICE = '_dd.base_service'
        end
      end
    end
  end
end
