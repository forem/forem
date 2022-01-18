class EmojiOnlyValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.gsub(EmojiRegex::RGIEmoji, "").blank?

    record.errors.add(attribute,
                      options[:message] || I18n.t("validators.emoji_only_validator.contains_non_emoji_charact"))
  end
end
