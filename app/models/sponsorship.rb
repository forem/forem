class Sponsorship < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :user, :organization, :featured_number, presence: true
  validates :level, inclusion: { in: %w[gold silver bronze tag media devrel] }
  validates :status, inclusion: { in: %w[none pending live] }
  validates :url, url: { allow_blank: true, no_local: true, schemes: %w[http https] }
end
