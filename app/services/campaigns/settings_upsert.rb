module Campaigns
  class SettingsUpsert
    attr_reader :errors

    def self.call(configs)
      new(configs).call
    end

    def initialize(configs)
      @configs = configs
      @errors = []
    end

    def call
      upsert_configs
      self
    end

    def success?
      @errors.none?
    end

    private

    # NOTE: @citizen428 - This was adapted from Settings::Upsert. I'll see if
    # a pattern for refactoring emerges in the future, but for now I'll leave
    # this as-is.
    def upsert_configs
      @configs.each do |key, value|
        if value.is_a?(Array) && value.any?
          Settings::Campaign.public_send("#{key}=", value.reject(&:blank?))
        elsif value.present?
          Settings::Campaign.public_send("#{key}=", value.strip)
        end
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        next
      end
    end
  end
end
