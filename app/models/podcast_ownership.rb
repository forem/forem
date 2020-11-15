class PodcastOwnership < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :podcast
end
