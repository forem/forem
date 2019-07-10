class Sponsorship < ApplicationRecord
  belongs_to :user
  belongs_to :organization, inverse_of: :sponsorships
  belongs_to :sponsorable, polymorphic: true, optional: true

  validates :user, :organization, :featured_number, presence: true
  validates :level, inclusion: { in: %w[gold silver bronze tag media devrel] }
  validates :status, inclusion: { in: %w[none pending live] }
  validates :url, url: { allow_blank: true, no_local: true, schemes: %w[http https] }
end
