if Rails.env.test?
  Honeycomb.configure do |config|
    config.client = Libhoney::TestClient.new
  end

  HoneycombClient = Libhoney::TestClient.new
else
  honeycomb_api_key = ApplicationConfig["HONEYCOMB_API_KEY"]

  # Honeycomb automatic Rails integration
  Honeycomb.configure do |config|
    config.write_key = honeycomb_api_key
    config.dataset = "rails"
    config.notification_events = %w[
      sql.active_record
      render_template.action_view
      render_partial.action_view
      render_collection.action_view
      process_action.action_controller
      send_file.action_controller
      send_data.action_controller
      deliver.action_mailer
    ].freeze
  end

  # here we create an additional Honeycomb client that can be used to send custom events
  HoneycombClient = Libhoney::Client.new(writekey: honeycomb_api_key, dataset: "dev-ruby")
end
