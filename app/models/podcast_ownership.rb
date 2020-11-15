class PodcastOwnership < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :podcast
  validates :podcast_id, uniqueness: { scope: :owner_id }
  validates :podcast_id, :owner_id, :role, presence: true
end
