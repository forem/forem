class CrossModelSlugValidator < ActiveModel::EachValidator
  FORMAT_REGEX = /\A[0-9a-z\-_]+\z/
  ORGANIZATION_FORMAT_REGEX = /\A(?![0-9]+\z)[0-9a-z\-_]+\z/
  ## allow / in page slugs
  PAGE_FORMAT_REGEX = /\A[0-9a-z\-_\/]+\z/
  PAGE_DIRECTORY_LIMIT = 6

  def validate_each(record, attribute, value)
    return if value.blank?

    correct_format?(record, attribute, value)
    allowed_subdirectory_count?(record, attribute, value)
    not_on_reserved_list?(record, attribute, value)
    unique_across_models?(record, attribute, value)
  end

  private

  def not_on_reserved_list?(record, attribute, value)
    return false if record.instance_of?(::Page) || ReservedWords.all.exclude?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_reserved"))
  end

  def correct_format?(record, attribute, value)
    format_regex = case record.class.name
                   when "Organization"
                     ORGANIZATION_FORMAT_REGEX
                   when "Page"
                     PAGE_FORMAT_REGEX
                   else
                     FORMAT_REGEX
                   end
    return false if value.match?(format_regex)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_invalid"))
  end

  def unique_across_models?(record, attribute, value)
    # attribute_changed? is likely redundant, but is much cheaper than the cross-model exists check
    return false unless record.public_send("#{attribute}_changed?")
    return false unless already_exists?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_taken"))
  end

  def allowed_subdirectory_count?(record, attribute, value)
    return false unless record.instance_of?(::Page)
    return false if value.split("/").count <= PAGE_DIRECTORY_LIMIT

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.too_many_subdirectories"))
  end

  def already_exists?(value)
    CrossModelSlug.exists?(value.downcase)
  end
end
