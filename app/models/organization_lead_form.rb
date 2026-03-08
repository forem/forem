class OrganizationLeadForm < ApplicationRecord
  belongs_to :organization
  has_many :lead_submissions, dependent: :destroy

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 500 }
  validates :button_text, presence: true, length: { maximum: 40 }

  scope :active, -> { where(active: true) }
end
