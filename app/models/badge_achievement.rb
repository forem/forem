class BadgeAchievement < ApplicationRecord
  belongs_to :user
  belongs_to :badge
  belongs_to :rewarder, class_name: "User"
end
