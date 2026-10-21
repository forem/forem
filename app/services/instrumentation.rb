module Instrumentation
  module_function

  def instrument(operation, tags: [], **options)
    # TODO: (@jgaskins): Extract the knowledge of which tracing library
    # we're using, like we did with ForemStatsDriver
    Datadog::Tracing.trace(operation, tags: tags, **options) do
      next yield unless defined?(Sentry) && Sentry.initialized? && Sentry.get_current_scope.get_transaction&.sampled

      Sentry.with_child_span(op: operation, description: options[:resource] || operation) do |span|
        if span
          if tags.respond_to?(:each_pair)
            tags.each_pair { |key, value| span.set_data(key.to_s, value) }
          elsif tags.present?
            span.set_data("tags", Array(tags))
          end
        end
        yield
      end
    end
  end
end
