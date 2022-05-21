module Instrumentation
  def instrument(operation, tags: [], &block)
    # TODO: (@jgaskins): Extract the knowledge of which tracing library
    # we're using, like we did with ForemStatsDriver
    Datadog::Tracing.trace operation, tags: tags, &block
  end
end
