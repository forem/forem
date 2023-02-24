module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, inverse_of: :reactable, dependent: :destroy
  end

  def sync_reactions_count
    update_column(:public_reactions_count, reactions.public_category.size)
  end

  def public_reaction_categories
    @public_reaction_categories ||= begin
      reacted = reactions.distinct(:category).pluck(:category)
      ReactionCategory.for_view
        .select do |reaction_type|
        reacted.include?(reaction_type.slug.to_s)
      end
    end
  end
end
