class EnabledCountriesHashValidator < ActiveModel::EachValidator
  VALID_HASH_VALUES = %i[with_regions without_regions].freeze

  def validate_each(record, attribute, value)
    if value.blank? || !value.is_a?(Hash)
      record.errors.add(attribute,
                        options[:message] || I18n.t("validators.iso3166_hash_validator.is_blank"))
      return
    end

    unless value.keys.all? { |key| ISO3166::Country.codes.include? key }
      record.errors.add(attribute,
                        options[:message] || I18n.t("validators.iso3166_hash_validator.invalid_key"))
    end

    return if value.values.all? { |value| VALID_HASH_VALUES.include? value }

    record.errors.add(attribute,
                      options[:message] || I18n.t("validators.iso3166_hash_validator.invalid_value"))
  end
end
