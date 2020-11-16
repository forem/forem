class PodcastOwnership < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :podcast
  validates :podcast_id, presence: true
  validates :user_id, presence: true
end
