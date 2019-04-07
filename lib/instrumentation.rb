require "rack/honeycomb/middleware"

module Instrumentation
  def self.included(base)
    base.before_action :add_user_info_to_honeycomb_event
  end

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

  def add_user_info_to_honeycomb_event
    return unless current_user

    Rack::Honeycomb.add_field(request.env, "user.id", current_user.id)
    Rack::Honeycomb.add_field(request.env, "user.email", current_user.email)
  end
end
