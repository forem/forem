module ActsAsTaggableOn
  class TagParser < GenericParser
    def parse
      ActsAsTaggableOn::TagList.new.tap do |tag_list|
        tag_list.add replace_with_tag_alias(clean(@tag_list))
      end
    end

    private

    def clean(string)
      string = string.to_s
      return [] if string.blank?

      string.downcase.split(",").map do |t|
        t.strip.delete(" ").gsub(/[^[:alnum:]]/i, "")
      end
    end

    def replace_with_tag_alias(tags)
      tags.map do |tag|
        possible_alias = tag
        found_alias = tag
        until possible_alias.nil?
          possible_alias = find_tag_alias(possible_alias)
          found_alias = possible_alias if possible_alias
        end
        found_alias
      end
    end

    def find_tag_alias(tag)
      # "&." is "Safe Navigation"; ensure not called on nil
      alias_for = Tag.find_by(name: tag)&.alias_for
      alias_for.presence
    end
  end
end
