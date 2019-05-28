class Poll < ApplicationRecord
  validates :prompt, presence: true
end
