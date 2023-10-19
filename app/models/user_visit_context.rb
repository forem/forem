class UserVisitContext < ApplicationRecord
  belongs_to :user
  has_many :ahoy_visits, class_name: "Ahoy::Visit", dependent: :nullify
end
