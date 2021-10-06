if Rails.env.test?
  Honeycomb.configure do |config|
    config.client = Libhoney::TestClient.new
  end
else
  honeycomb_api_key = ApplicationConfig["HONEYCOMB_API_KEY"]
  release_footprint = ApplicationConfig["RELEASE_FOOTPRINT"]

  # Honeycomb automatic Rails integration
  notification_events = %w[
    cache_read.active_support
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
    config.write_key = honeycomb_api_key.presence

    # libhoney client will automatically fall back to using a null transmission
    # when no write key is provided, but it will log a warning (visible in a few places)
    # explicitly override the client to disable the warning
    config.client = Libhoney::NullClient.new unless config.write_key

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
end
