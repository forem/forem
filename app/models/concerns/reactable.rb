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

  def sync_reactions_count
    update_column(:public_reactions_count, reactions.public_category.size)
  end

  def public_reaction_categories
    @public_reaction_categories ||= begin
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
