module Reactable
  extend ActiveSupport::Concern

  included do
    has_many :reactions, as: :reactable, dependent: :destroy
  end

  def sync_reactions_count
    update_column(:positive_reactions_count, reactions.where("points > ?", 0).size)
  end
end
