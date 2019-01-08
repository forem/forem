class Collection < ApplicationRecord
  has_many :articles
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  validates :user_id, presence: true
  validates :slug, uniqueness: { scope: :user_id }

  def self.find_series(slug, user)
    series = Collection.where(slug: slug, user: user).first
    series || Collection.create(slug: slug, user: user)
  end
end
