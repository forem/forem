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
          settings_class.public_send("#{key}=", value.reject(&:blank?))
        elsif value.respond_to?(:to_h) && value.present?
          settings_class.public_send("#{key}=", value.to_h)
        elsif value.present?
          settings_class.public_send("#{key}=", value.strip)
        elsif value.blank?
          settings_class.public_send("#{key}=", nil)
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        next
      end
    end
  end
end
