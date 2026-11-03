class EmojiOnlyValidator < ActiveModel::EachValidator
  # Validates that `value` consists solely of Unicode `RGI_Emoji` sequences (and/or whitespace)
  # using `ForemNative.strip_rgi_emoji` (see `crates/forem_core/src/emoji_data.rs` for updating
  # the embedded Unicode `RGI_Emoji` table when adopting new Unicode Emoji releases).
  def validate_each(record, attribute, value)
    return unless value
    return if ForemNative.strip_rgi_emoji(value.to_s).blank?

    record.errors.add(attribute,
                      options[:message] || I18n.t("validators.emoji_only_validator.invalid_emoji"))
  end
end
