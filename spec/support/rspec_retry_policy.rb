module RSpecRetryPolicy
  # Tagged retries must opt out of the global PG-only filter so their retry counts take effect.
  NO_EXCEPTION_FILTER = [].freeze
  JS_OPTIONS = { retry: 3, exceptions_to_retry: NO_EXCEPTION_FILTER }.freeze
  FLAKY_OPTIONS = { retry: 5, exceptions_to_retry: NO_EXCEPTION_FILTER }.freeze

  module_function

  def compose_callbacks(*callbacks)
    active_callbacks = callbacks.compact

    proc do |example|
      active_callbacks.each { |callback| instance_exec(example, &callback) }
    end
  end
end
