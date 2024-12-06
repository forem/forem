# frozen_string_literal: true

require_relative '../contrib/http/distributed/propagation'

module Datadog
  module Tracing
    module Propagation
      # Propagation::HTTP helps extracting and injecting HTTP headers.
      # DEV-2.0: This file has been moved to Contrib. Should be deleted in the next release.
      # @public_api
      HTTP = Tracing::Contrib::HTTP::Distributed::Propagation.new
    end
  end
end
