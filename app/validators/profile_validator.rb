class ProfileValidator < ActiveModel::Validator
  SUMMARY_ATTRIBUTE = "summary".freeze
  MAX_SUMMARY_LENGTH = 200

  MAX_TEXT_AREA_LENGTH = 200
  MAX_TEXT_FIELD_LENGTH = 100

  ERRORS = {
    text_area: "is too long (maximum is #{MAX_TEXT_AREA_LENGTH} characters)",
    text_field: "is too long (maximum is #{MAX_TEXT_FIELD_LENGTH} characters)"
  }.with_indifferent_access.freeze

  def validate(record)
    # NOTE: @citizen428 The summary is a base profile field, which we add to all
    # new Forem instances, so it should be safe to validate. The method itself
    # also guards against the field's absence.
    record.errors.add(:summary, "is too long") if summary_too_long?(record)

    ProfileField.all.each do |field|
      attribute = field.attribute_name
      next if attribute == SUMMARY_ATTRIBUTE # validated above
      next unless record.respond_to?(attribute) # avoid caching issues
      next if __send__("#{field.input_type}_valid?", record, attribute)

      record.errors.add(attribute, ERRORS[field.input_type])
    end
  end

  private

  def summary_too_long?(record)
    return if record.summary.blank?

    # Grandfather in people who had a too long summary before
    previous_summary = record.summary_was
    return if previous_summary && previous_summary.size > MAX_SUMMARY_LENGTH

    record.summary.size > MAX_SUMMARY_LENGTH
  end

  def check_box_valid?(_record, _attribute)
    true # checkboxes are always valid
  end

  def color_field_valid?(_record, _attribute)
    true # we do not currently validate color fields here
  end

  def text_area_valid?(record, attribute)
    text = record.public_send(attribute)
    text.nil? || text.size <= MAX_TEXT_AREA_LENGTH
  end

  def text_field_valid?(record, attribute)
    text = record.public_send(attribute)
    text.nil? || text.size <= MAX_TEXT_FIELD_LENGTH
  end
end
