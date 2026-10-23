module Instrumentation
  module_function

  def instrument(operation, tags: [], **options, &block)
    if defined?(Datadog::Tracing) && ENV["DD_API_KEY"].present?
      Datadog::Tracing.trace(operation, tags: tags, **options) do
        trace_with_sentry(operation, tags: tags, **options, &block)
      end
    else
      trace_with_sentry(operation, tags: tags, **options, &block)
    end
  end

  def trace_with_sentry(operation, tags: [], **options)
    return yield unless defined?(Sentry) && Sentry.initialized? && Sentry.get_current_scope.get_transaction&.sampled

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
  private_class_method :trace_with_sentry
end
