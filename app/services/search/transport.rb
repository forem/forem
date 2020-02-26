module Search
  module Transport
    extend ActiveSupport::Concern

    class_methods do
      private

      TRANSPORT_EXCEPTIONS = [
        Elasticsearch::Transport::Transport::Errors::BadRequest,
        Elasticsearch::Transport::Transport::Errors::NotFound,
      ].freeze

      def request
        yield
      rescue *TRANSPORT_EXCEPTIONS => e
        class_name = e.class.name.demodulize

        DatadogStatsClient.increment("elasticsearch.errors", tags: ["error:#{class_name}"], message: e.message)

        # raise specific error if known, generic one if unknown
        error_class = "::Search::Errors::Transport::#{class_name}".safe_constantize
        raise error_class, e.message if error_class

        raise ::Search::Errors::TransportError, e.message
      end
    end
  end
end
