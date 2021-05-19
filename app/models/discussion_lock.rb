class DiscussionLock < ApplicationRecord
  belongs_to :article
  belongs_to :user

  validates :article_id, presence: true, uniqueness: true
  validates :user_id, presence: true
end
