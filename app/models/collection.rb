class Collection < ApplicationRecord
  include Localizable

  has_many :articles, dependent: :nullify

  belongs_to :user
  belongs_to :organization, optional: true

  validates :slug, presence: true, uniqueness: { scope: :user_id }

  scope :non_empty, -> { joins(:articles).distinct }

  after_touch :touch_articles

  def self.find_series(slug, user)
    Collection.find_or_create_by(slug: slug, user: user)
  end

  def unlocalized_path
    "/#{user.username}/series/#{id}"
  end

  private

  def touch_articles
    articles.touch_all
  end
end
