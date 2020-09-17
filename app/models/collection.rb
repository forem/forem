class Collection < ApplicationRecord
  has_many :articles, dependent: :nullify

  belongs_to :user
  belongs_to :organization, optional: true

  validates :user_id, presence: true
  validates :slug, presence: true, uniqueness: { scope: :user_id }

  after_touch :touch_articles

  def self.find_series(slug, user)
    Collection.find_or_create_by(slug: slug, user: user)
  end

  def path
    "/#{user.username}/series/#{id}"
  end

  private

  def touch_articles
    articles.touch_all
  end
end
