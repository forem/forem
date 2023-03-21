##
# Validates if the give attribute is used across the reserved spaces.
class CrossModelSlugValidator < ActiveModel::EachValidator
  FORMAT_REGEX = /\A[0-9a-z\-_]{2,}\z/

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
    format(record, attribute, value)
    reserved(record, attribute, value)
    uniqueness(record, attribute, value)
  end

  private

  def reserved(record, attribute, value)
    return unless ReservedWords.all.include?(value)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_reserved"))
  end

  def format(record, attribute, value)
    return if value.match?(FORMAT_REGEX)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_invalid"))
  end

  def uniqueness(record, attribute, value)
    return unless already_exists?(value: value, record: record, attribute: attribute)

    record.errors.add(attribute, I18n.t("validators.cross_model_slug_validator.is_taken"))
  end

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
  def already_exists?(record:, attribute:, value:)
    return false unless value
    return true if value.include?("sitemap-")

    model_and_attribute_name_for_uniqueness_test.detect do |model, attr|
      next unless record.public_send("#{attribute}_changed?")

      model.exists?(attr => value.downcase)
    end
  end
end
