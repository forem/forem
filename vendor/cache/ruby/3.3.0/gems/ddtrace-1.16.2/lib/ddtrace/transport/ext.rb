# frozen_string_literal: true

require_relative '../../datadog/core/transport/ext'
# DEV(2.0): This file should be replaced by /datadog/core/transport/ext.rb.
module Datadog
  module Transport
    # @public_api
    module Ext
      # @public_api
      module HTTP
        ADAPTER = Datadog::Core::Transport::Ext::HTTP::ADAPTER
        DEFAULT_HOST = Datadog::Core::Transport::Ext::HTTP::DEFAULT_HOST
        DEFAULT_PORT = Datadog::Core::Transport::Ext::HTTP::DEFAULT_PORT

        HEADER_CONTAINER_ID = Datadog::Core::Transport::Ext::HTTP::HEADER_CONTAINER_ID
        HEADER_DD_API_KEY = Datadog::Core::Transport::Ext::HTTP::HEADER_DD_API_KEY
        # Tells agent that `_dd.top_level` metrics have been set by the tracer.
        # The agent will not calculate top-level spans but instead trust the tracer tagging.
        #
        # This prevents partially flushed traces being mistakenly marked as top-level.
        #
        # Setting this header to any non-empty value enables this feature.
        HEADER_CLIENT_COMPUTED_TOP_LEVEL = Datadog::Core::Transport::Ext::HTTP::HEADER_CLIENT_COMPUTED_TOP_LEVEL
        HEADER_META_LANG = Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG
        HEADER_META_LANG_VERSION = Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG_VERSION
        HEADER_META_LANG_INTERPRETER = Datadog::Core::Transport::Ext::HTTP::HEADER_META_LANG_INTERPRETER
        HEADER_META_TRACER_VERSION = Datadog::Core::Transport::Ext::HTTP::HEADER_META_TRACER_VERSION

        # Header that prevents the Net::HTTP integration from tracing internal trace requests.
        # Set it to any value to skip tracing.
        HEADER_DD_INTERNAL_UNTRACED_REQUEST = Datadog::Core::Transport::Ext::HTTP::HEADER_DD_INTERNAL_UNTRACED_REQUEST
      end

      # @public_api
      module Test
        ADAPTER = Datadog::Core::Transport::Ext::Test::ADAPTER
      end

      # @public_api
      module UnixSocket
        ADAPTER = Datadog::Core::Transport::Ext::UnixSocket::ADAPTER
        DEFAULT_PATH = Datadog::Core::Transport::Ext::UnixSocket::DEFAULT_PATH
        DEFAULT_TIMEOUT_SECONDS = Datadog::Core::Transport::Ext::UnixSocket::DEFAULT_TIMEOUT_SECONDS
      end
    end
  end
end
