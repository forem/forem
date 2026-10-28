honeycomb_api_key = ApplicationConfig["HONEYCOMB_API_KEY"].presence

if honeycomb_api_key
  require "honeycomb-beeline"
  require_relative "../../app/lib/honeycomb/noise_cancelling_sampler"

  release_footprint = ApplicationConfig["RELEASE_FOOTPRINT"]

  # Honeycomb automatic Rails integration
  notification_events = %w[
    cache_read.active_support
    cache_read_multi.active_support
    sql.active_record
    render_template.action_view
    render_partial.action_view
    render_collection.action_view
    process_action.action_controller
    send_file.action_controller
    send_data.action_controller
    deliver.action_mailer
  ].freeze

  Honeycomb.configure do |config|
    config.write_key = honeycomb_api_key

    if ENV["HONEYCOMB_DISABLE_AUTOCONFIGURE"]
      config.dataset = "background-work"
    else
      config.dataset = "rails"
      config.notification_events = notification_events

      # Scrub unused data to save space in Honeycomb
      config.presend_hook do |fields|
        fields["global.build_id"] = release_footprint

        if fields.key?("redis.command")
          fields["redis.command"] = fields["redis.command"].slice(0, 300)
        elsif fields.key?("sql.active_record.binds")
          fields.delete("sql.active_record.binds")
          fields.delete("sql.active_record.datadog_span")
        end
      end
      # Sample away highly redundant events
      config.sample_hook do |fields|
        Honeycomb::NoiseCancellingSampler.sample(fields)
      end
    end
  end

  if defined?(Honeycomb::Rails::Middleware) && !ENV["HONEYCOMB_DISABLE_AUTOCONFIGURE"]
    Rails.application.config.middleware.insert_after(
      ActionDispatch::ShowExceptions,
      Honeycomb::Rails::Middleware,
      client: Honeycomb.client,
    )
  end
else
  module Honeycomb
    @client = nil
  end
end

module Honeycomb
  def self.add_field(key, value)
    @client&.add_field(key, value)
  end

  def self.start_span(**fields, &block)
    return @client.start_span(**fields, &block) if @client

    block ? yield(self) : self
  end
end
