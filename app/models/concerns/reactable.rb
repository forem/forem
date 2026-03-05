module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, inverse_of: :reactable, dependent: :destroy
    has_many :distinct_reaction_categories, -> { order(:category).merge(Reaction.distinct_categories) },
             as: :reactable,
             inverse_of: :reactable,
             dependent: nil,
             class_name: "Reaction"
  end

  class_methods do
    # Batch sync reaction counts for multiple records efficiently
    # Eliminates N+1 queries by using a single grouped query + batch update
    #
    # @param records [Array<ActiveRecord::Base>] records to sync
    # @return [Integer] number of records updated
    def sync_reactions_count_for_batch(records)
      return 0 if records.empty?

      ids = records.map(&:id)

      # Single grouped query to get correct counts for all records
      correct_counts = Reaction
        .where(reactable_type: name, reactable_id: ids)
        .public_category
        .group(:reactable_id)
        .count

      # Build SQL CASE statement for efficient batch update
      sanitized_ids = ids.map { |id| ActiveRecord::Base.connection.quote(id) }
      when_clauses = ids.map do |id|
        count = correct_counts[id] || 0
        "WHEN #{ActiveRecord::Base.connection.quote(id)} THEN #{count}"
      end.join(" ")

      sql = <<~SQL.squish
        UPDATE #{table_name}
        SET public_reactions_count = CASE id
          #{when_clauses}
        END
        WHERE id IN (#{sanitized_ids.join(',')})
      SQL

      ActiveRecord::Base.connection.execute(sql)
      ids.size
    end
  end

  def sync_reactions_count
    # Use direct SQL update to avoid race conditions and callbacks
    correct_count = reactions.public_category.count
    self.class.where(id: id).update_all(public_reactions_count: correct_count)
  end

  def public_reaction_categories
    # Get reaction counts for this reactable
    reaction_counts = reaction_counts_for_reactable
    
    # Filter to only public reaction categories that have reactions
    categories_with_counts = reaction_counts.select do |count_data|
      category_slug = count_data[:category]
      count_data[:count] > 0 && ReactionCategory[category_slug]&.visible_to_public?
    end
    
    # Sort by count (descending), then by position for ties, and limit to 3
    sorted_categories = categories_with_counts
      .sort_by { |count_data| [-count_data[:count], ReactionCategory[count_data[:category]]&.position || 99] }
      .first(3)
    
    # Convert back to ReactionCategory objects
    sorted_categories.map do |count_data|
      ReactionCategory[count_data[:category]]
    end
  end

  private

  def reaction_counts_for_reactable
    return [] unless respond_to?(:id)
    
    Rails.cache.fetch("reaction_counts_for_reactable-#{self.class.name}-#{id}", expires_in: 10.hours) do
      reactions.group(:category).count.map do |category, count|
        { category: category, count: count }
      end
    end
  end
end
