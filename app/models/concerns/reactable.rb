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
      # .map is intentional below - .pluck would break eager-loaded association!
      reacted = distinct_reaction_categories.map(&:category)
      ReactionCategory.for_view.select do |reaction_type|
        reacted.include?(reaction_type.slug.to_s)
      end
    end
  end
end
