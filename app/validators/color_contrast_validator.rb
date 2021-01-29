class ColorContrastValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "must be darker for accessibility".freeze

  def validate_each(record, attribute, value)
    return unless Color::Accessibility.new(value).low_contrast?

    record.errors.add(attribute, (options[:message] || DEFAULT_MESSAGE))
  rescue WCAGColorContrast::InvalidColorError
    # nothing to do here, this should be picked up by the format validation
  end
end
