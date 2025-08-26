class Survey < ApplicationRecord
  has_many :polls, -> { order(:position) }, dependent: :nullify
end
