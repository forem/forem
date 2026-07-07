class ConceptAccess < ApplicationRecord
  belongs_to :user
  belongs_to :concept

  validates :user_id, uniqueness: { scope: :concept_id }
end
