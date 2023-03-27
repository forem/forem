##
# Validates if the give attribute is used across the reserved spaces.
class CrossModelSlugValidator < ActiveModel::EachValidator
  FORMAT_REGEX = /\A[0-9a-z\-_]+\z/

  def validate_each(record, attribute, value)
    return if value.blank?

    correct_format?(record, attribute, value)
    not_on_reserved_list?(record, attribute, value)
    unique_across_models?(record, attribute, value)
  end

  private

  def not_on_reserved_list?(record, attribute, value)
    return unless ReservedWords.all.include?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_reserved"))
  end

  def correct_format?(record, attribute, value)
    return if value.match?(FORMAT_REGEX)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_invalid"))
  end

  def unique_across_models?(record, attribute, value)
    # attribute_changed? is likely redundant, but is much cheaper than the cross-model exists check
    return unless record.public_send("#{attribute}_changed?")
    return unless already_exists?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_taken"))
  end

  def already_exists?(value)
    CrossModelSlug.exists?(value.downcase)
  end
end
