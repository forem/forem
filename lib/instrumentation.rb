require "rack/honeycomb/middleware"

module Instrumentation
  def add_param_context(*keys)
    keys.each do |key|
      Rack::Honeycomb.add_field(request.env, key, params[key])
    end
  end

  def add_context(metadata)
    metadata.each do |key, value|
      Rack::Honeycomb.add_field(request.env, key, value)
    end
  end

  def append_to_honeycomb(request, controller_name)
    Rack::Honeycomb.add_field(request.env, "trace.trace_id", request.request_id)
    Rack::Honeycomb.add_field(request.env, "trace.span_id", request.request_id)
    Rack::Honeycomb.add_field(request.env, :service_name, "rails")
    Rack::Honeycomb.add_field(request.env, :name, controller_name)
  end
end
