module Settings
  # This service ensures that settings upserts to the database happen in a
  # standardized way. Instead of subclassing this service I recommend wrapping
  # it, see e.g. Settings::General::Upsert.
  class Upsert
    attr_reader :errors, :settings_class

    def self.call(settings, settings_class)
      new(settings, settings_class).call
    end

    def initialize(settings, settings_class)
      @settings = settings
      @settings_class = settings_class
      @errors = []
      @subforem_id = RequestStore.store[:subforem_id]
    end

    def call
      upsert_settings
      self
    end

    def success?
      @errors.none?
    end

    def upsert_settings
      @settings.each do |key, value|
        if value.is_a?(Array) && value.any?
          settings_class.public_send("set_#{key}", value.compact_blank, subforem_id: @subforem_id)
        elsif value.respond_to?(:to_h) && value.present?
          settings_class.public_send("set_#{key}", value.to_h, subforem_id: @subforem_id)
        elsif value.present?
          settings_class.public_send("set_#{key}", value.strip, subforem_id: @subforem_id)
        elsif value.blank?
          settings_class.public_send("set_#{key}", nil, subforem_id: @subforem_id)
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        next
      end
    end    
  end
end
