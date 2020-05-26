module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, inverse_of: :reactable, dependent: :destroy
  end

  def sync_reactions_count
    update_column(:public_reactions_count, reactions.public_category.size)
  end
end
