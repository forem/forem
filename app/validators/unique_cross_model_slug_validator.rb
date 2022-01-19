##
# Validates if the give attribute is used across the reserved spaces.
class UniqueCrossModelSlugValidator < ActiveModel::EachValidator
  class_attribute :model_and_attribute_name_for_uniqueness_test

  # Why a class attribute?  Allow for other implementations to extend
  # this behavior.
  self.model_and_attribute_name_for_uniqueness_test = {
    Organization => :slug,
    Page => :slug,
    Podcast => :slug,
    User => :username
  }

  def validate_each(record, attribute, value)
    return unless already_exists?(value: value, record: record)

    record.errors.add(attribute, options[:message] || I18n.t("validators.unique_cross_model_slug_validator.is_taken"))
  end

  private

  ##
  # Answers the question if it's okay for the record to use the given value.
  #
  # @param value [String] the value we're to check in the various classes
  # @param record [ActiveRecord::Base] the record that we're attempting to validate
  #
  # @return [TrueClass] if the value already exists across the various classes.
  # @return [FalseClass] if the given value is not already used.
  #
  # @see CLASS_AND_ATTRIBUTE_NAME_FOR_UNIQUENESS_TEST
  def already_exists?(value:, record:)
    return false unless value
    return true if value.include?("sitemap-")

    model_and_attribute_name_for_uniqueness_test.detect do |model, attribute|
      next if record.is_a?(model)

      model.exists?(attribute => value)
    end
  end
end
