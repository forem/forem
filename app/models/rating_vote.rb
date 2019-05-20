class RatingVote < ApplicationRecord
  belongs_to :article
  belongs_to :user

  validates :user_id, uniqueness: { scope: :article_id }
  validates :group, inclusion: { in: %w[experience_level] }
  validates :rating, numericality: { greater_than: 0.0, less_than_or_equal_to: 10.0 }
  validate :permissions
  counter_culture :article
  counter_culture :user

  def assign_article_rating
    ratings = article.rating_votes.where(group: group).pluck(:rating)
    average = ratings.sum / ratings.size
    article.update_column(:experience_level_rating, average)
    article.update_column(:experience_level_rating_distribution, ratings.sort.max - ratings.sort.min)
    article.update_column(:last_experience_level_rating_at, Time.current)
  end

  private

  def permissions
    errors.add(:user_id, "is not permitted to take this action.") if !user&.trusted && user_id != article&.user_id
  end
end
