class RatingVote < ApplicationRecord
  belongs_to :article
  belongs_to :user, optional: true

  validates :context, inclusion: { in: %w[explicit readinglist_reaction comment] }
  validates :group, inclusion: { in: %w[experience_level] }
  validates :rating, numericality: { greater_than: 0.0, less_than_or_equal_to: 10.0 }
  validates :user_id, presence: true, on: :create
  validates :user_id, uniqueness: { scope: %i[article_id context] }

  validate :permissions

  after_create_commit :assign_article_rating

  counter_culture :article
  counter_culture :user

  private

  def assign_article_rating
    RatingVotes::AssignRatingWorker.perform_async(article_id)
  end

  def permissions
    return if user == article&.user || user&.trusted? || context != "explicit"

    errors.add(:user_id, "is not permitted to take this action.")
  end
end
