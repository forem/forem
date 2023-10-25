##
# Validates if the give attribute is used across the reserved spaces.
class CrossModelSlugValidator < ActiveModel::EachValidator
  FORMAT_REGEX = /\A[0-9a-z\-_]+\z/
  ORGANIZATION_FORMAT_REGEX = /\A(?![0-9]+\z)[0-9a-z\-_]+\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    correct_format?(record, attribute, value)
    not_on_reserved_list?(record, attribute, value)
    unique_across_models?(record, attribute, value)
  end

  private

  def not_on_reserved_list?(record, attribute, value)
    return false if record.instance_of?(::Page) || ReservedWords.all.exclude?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_reserved"))
  end

  def correct_format?(record, attribute, value)
    format_regex = record.is_a?(Organization) ? ORGANIZATION_FORMAT_REGEX : FORMAT_REGEX
    return false if value.match?(format_regex)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_invalid"))
  end

  def unique_across_models?(record, attribute, value)
    # attribute_changed? is likely redundant, but is much cheaper than the cross-model exists check
    return false unless record.public_send("#{attribute}_changed?")
    return false unless already_exists?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_taken"))
  end

  def already_exists?(value)
    CrossModelSlug.exists?(value.downcase)
  end
end
