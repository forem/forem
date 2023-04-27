class SegmentedUser < ApplicationRecord
  belongs_to :audience_segment
  belongs_to :user
end
