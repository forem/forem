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

  counter_culture :article,
                  column_name: proc { |model| "rating_votes_count" unless model.destroyed_by_article_association? },
                  column_names: { nil => :rating_votes_count }
  counter_culture :user

  def destroyed_by_article_association?
    destroyed_by_association&.active_record == Article
  end

  private

  def assign_article_rating
    RatingVotes::AssignRatingWorker.perform_async(article_id)
  end

  def permissions
    return unless context == "explicit" && !user&.trusted? && user_id != article&.user_id

    errors.add(:user_id, I18n.t("models.rating_vote.not_permitted"))
  end
end
