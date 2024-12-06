# frozen_string_literal: true

require_relative '../../../distributed/fetcher'
require_relative '../../../distributed/propagation'
require_relative '../../../distributed/b3_multi'
require_relative '../../../distributed/b3_single'
require_relative '../../../distributed/datadog'
require_relative '../../../distributed/none'
require_relative '../../../distributed/trace_context'
require_relative '../../../configuration/ext'

module Datadog
  module Tracing
    module Contrib
      module Sidekiq
        module Distributed
          # Extracts and injects propagation through HTTP headers.
          class Propagation < Tracing::Distributed::Propagation
            def initialize
              super(
                propagation_styles: {
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_MULTI_HEADER =>
                    Tracing::Distributed::B3Multi.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_B3_SINGLE_HEADER =>
                    Tracing::Distributed::B3Single.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_DATADOG =>
                    Tracing::Distributed::Datadog.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_TRACE_CONTEXT =>
                    Tracing::Distributed::TraceContext.new(fetcher: Tracing::Distributed::Fetcher),
                  Tracing::Configuration::Ext::Distributed::PROPAGATION_STYLE_NONE => Tracing::Distributed::None.new
                })
            end
          end
        end
      end
    end
  end
end
