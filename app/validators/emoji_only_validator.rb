class EmojiOnlyValidator < ActiveModel::EachValidator
  DEFAULT_MESSAGE = "contains non-emoji characters or invalid emoji".freeze

  def validate_each(record, attribute, value)
    return if value.gsub(EmojiRegex::RGIEmoji, "").blank?

    record.errors.add(attribute, options[:message] || DEFAULT_MESSAGE)
  end
end
