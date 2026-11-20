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

      ForemNative.clean_tag_list(string) || legacy_clean(string)
    end

    def legacy_clean(string)
      string.downcase.split(",").map do |t|
        t.strip.delete(" ").gsub(/[^[:alnum:]]/i, "")
      end
    end

    def replace_with_tag_alias(tags)
      return [] if tags.empty?

      aliases_by_name = Tag.where(name: tags.uniq).pluck(:name, :alias_for).to_h
      tags.map do |tag|
        possible_alias = aliases_by_name[tag].presence
        found_alias = possible_alias || tag
        while possible_alias
          possible_alias = if aliases_by_name.key?(possible_alias)
                             aliases_by_name[possible_alias].presence
                           else
                             aliases_by_name[possible_alias] = find_tag_alias(possible_alias)
                           end
          found_alias = possible_alias if possible_alias
        end
        found_alias
      end
    end

    def find_tag_alias(tag)
      # "&." is "Safe Navigation"; ensure not called on nil
      alias_for = Tag.where(name: tag).pick(:alias_for)
      alias_for.presence
    end
  end
end
