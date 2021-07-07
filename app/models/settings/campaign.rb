module Settings
  class Campaign < Base
    self.table_name = :settings_campaigns

    # Define your settings
    setting :articles_expiry_time, type: :integer, default: 4
    setting :articles_require_approval, type: :boolean, default: 0
    setting :call_to_action, type: :string, default: "Share your project"
    setting :featured_tags, type: :array, default: %w[]
    setting :hero_html_variant_name, type: :string, default: ""
    setting :sidebar_enabled, type: :boolean, default: 0
    setting :sidebar_image, type: :string, default: nil, validates: { url: true }
    setting :url, type: :string, default: nil
  end
end
