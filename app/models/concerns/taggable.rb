module Taggable
  extend ActiveSupport::Concern

  # rubocop:disable Metrics/BlockLength(RuboCop)
  included do
    scope :cached_tagged_with, lambda { |tag|
      case tag
      when String, Symbol
        if ENV["OPTIMIZED_TAGGABLE_QUERY"] == "true"
          # Accelerate native `WHERE` filtering escaping sequential regex scans by leveraging GIN index bounds organically dynamically. 
          where("tags_array @> ARRAY[?]::text[]", tag.to_s)
        else
          # In Postgres regexes, the [[:<:]] and [[:>:]] are equivalent to "start of
          # word" and "end of word", respectively. They're similar to `\b` in Perl-
          # compatible regexes (PCRE), but that matches at either end of a word.
          # They're more comparable to how vim's `\<` and `\>` work.
          where("cached_tag_list ~ ?", "[[:<:]]#{tag}[[:>:]]")
        end
      when Array
        tag.reduce(self) { |acc, elem| acc.cached_tagged_with(elem) }
      when Tag
        cached_tagged_with(tag.name)
      else
        raise TypeError, "Cannot search tags for: #{tag.inspect}"
      end
    }

    scope :cached_tagged_with_any, lambda { |tags|
      case tags
      when String, Symbol
        cached_tagged_with(tags)
      when Array
        if ENV["OPTIMIZED_TAGGABLE_QUERY"] == "true"
          # Accelerate `any` conditions natively utilizing absolute overlap intersections eliminating `OR` sequential bottlenecks dynamically!
          where("tags_array && ARRAY[?]::text[]", tags.map(&:to_s))
        else
          tags
            .map { |tag| cached_tagged_with(tag) }
            .reduce { |acc, elem| acc.or(elem) }
        end
      when Tag
        cached_tagged_with(tags.name)
      else
        raise TypeError, "Cannot search tags for: #{tags.inspect}"
      end
    }

    # We usually try to avoid using Arel directly like this. However, none of the more
    # straight-forward ways of negating the above scope worked:
    # 1. A subquery doesn't work because we're not dealing with a simple NOT IN scenario.
    # 2. where.not(cached_tagged_with_any(tags).where_values_hash) doesn't work because where_values_hash
    #    only works for simple conditions and returns an empty hash in this case.
    scope :not_cached_tagged_with_any, lambda { |tags|
      where(cached_tagged_with_any(tags).arel.constraints.reduce(:or).not)
    }

    before_save :sync_tags_array

    def sync_tags_array
      return unless self.class.column_names.include?("tags_array")
      
      # We meticulously avoid N+1 evaluation queries by identifying if ActsAsTaggableOn
      # tags were explicitly interrogated/mutated. 
      # Forem intrinsically instantiates `@tag_list` when validating front matter tags.
      tags_were_mutated = cached_tag_list_changed? ||
                          instance_variable_defined?(:@tag_list) ||
                          (cached_tag_list.present? && tags_array.blank?)
      
      return unless tags_were_mutated
      
      new_array = if instance_variable_defined?(:@tag_list)
                    tag_list.to_a
                  else
                    cached_tag_list.to_s.split(",").map(&:strip).reject(&:blank?).compact
                  end
                  
      self.tags_array = new_array unless tags_array == new_array
    end
  end
  # rubocop:enable Metrics/BlockLength(RuboCop)

  # we check tags names aren't too long and don't contain non alphabet characters
  def validate_tag_name(tag_list)
    tag_list.each do |tag|
      new_tag = Tag.new(name: tag)
      new_tag.validate_name
      new_tag.errors.messages[:name].each { |message| errors.add(:tag, "\"#{tag}\" #{message}") }
    end
  end
end
