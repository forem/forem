class FeedbackMessage < ApplicationRecord
  belongs_to :user, optional: true
end
