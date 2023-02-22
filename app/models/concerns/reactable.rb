module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, inverse_of: :reactable, dependent: :destroy
  end

  def sync_reactions_count
    update_column(:public_reactions_count, reactions.public_category.size)
  end

  def reaction_categories
    reactions.distinct(:category).pluck(:category)
  end

  def public_reaction_categories
    @public_reaction_categories ||= ReactionCategory.for_view
      .select do |reaction_type|
        reaction_categories.include?(reaction_type.slug.to_s)
      end
  end

  def public_reaction_category_count_hash
    @public_reaction_category_count_hash ||= reactions.public_category
      .order(:category)
      .select("category, COUNT(*)")
      .group("category")
      .distinct("category")
      .to_h { |result| [result["category"], result["count"]] }
  end
end
