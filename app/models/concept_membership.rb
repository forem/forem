class ConceptMembership < ApplicationRecord
  belongs_to :concept
  belongs_to :record, polymorphic: true

  validates :record_id, uniqueness: { scope: %i[concept_id record_type] }
  validates :distance, presence: true
end
