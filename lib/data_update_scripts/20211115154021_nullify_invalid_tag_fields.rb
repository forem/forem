module DataUpdateScripts
  class NullifyInvalidTagFields
    def run
      Tag.where(bg_color_hex: "").or(Tag.where(text_color_hex: "")).find_each do |tag|
        # presence here selects non-empty strings if set  (avoiding unsetting valid values)
        # but nullifies empty tag colors
        tag.update_columns(
          bg_color_hex: tag.bg_color_hex.presence,
          text_color_hex: tag.text_color_hex.presence,
        )
      end

      # normalize empty string to nil (alias_for? behaved correctly already), this is just cleanup
      Tag.where(alias_for: "").update(alias_for: nil)

      Tag.where.not(alias_for: nil).find_each do |aliased_tag|
        # this is expected to not do anything - based on this query in blazer giving 0 rows
        # (there are 64 with aliases, all valid)

        # SELECT tags.alias_for, t2.name FROM tags
        # LEFT JOIN tags AS t2 ON tags.alias_for = t2.name
        # WHERE tags.alias_for IS NOT NULL
        # AND tags.alias_for != ''
        # AND t2.name IS NULL;

        aliased_tag.validate

        if aliased_tag.errors.any? { |e| e.type == "alias_for must refer to an existing tag" }
          aliased_tag.update_column(:alias_for, nil)
        end
      end
    end
  end
end
