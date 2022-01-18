class ColorContrastValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless Color::Accessibility.new(value).low_contrast?

    record.errors.add(attribute,
                      (options[:message] || I18n.t("validators.color_contrast_validator.must_be_darker")))
  rescue WCAGColorContrast::InvalidColorError
    # nothing to do here, this should be picked up by the format validation
  end
end
