class PollSkip < ApplicationRecord
  belongs_to :poll
  belongs_to :user
end
