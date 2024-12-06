# frozen_string_literal: true

module ISO3166
  module LocalesMethods
    private

    def locales_to_load
      requested_locales - loaded_locales
    end

    def locales_to_remove
      loaded_locales - requested_locales
    end

    def requested_locales
      ISO3166.configuration.locales.map { |locale| locale.to_s.downcase }
    end

    def loaded_locales
      ISO3166.configuration.loaded_locales.map { |locale| locale.to_s.downcase }
    end
  end
end
