class Survey < ApplicationRecord
  has_many :polls, dependent: :nullify
end
