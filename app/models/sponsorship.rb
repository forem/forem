class Sponsorship < ApplicationRecord
  LEVELS = %w[gold silver bronze tag media devrel].freeze
  LEVELS_WITH_EXPIRATION = %w[gold silver bronze].freeze
  STATUSES = %w[none pending live].freeze
  # media has no fixed amount of credits
  CREDITS = {
    gold: 6_000,
    silver: 500,
    bronze: 100,
    tag: 300,
    devrel: 500
  }.with_indifferent_access.freeze

  belongs_to :user
  belongs_to :organization, inverse_of: :sponsorships
  belongs_to :sponsorable, polymorphic: true, optional: true

  validates :user, :organization, :featured_number, presence: true
  validates :level, inclusion: { in: LEVELS }
  validates :status, inclusion: { in: STATUSES }
  validates :url, url: { allow_blank: true, no_local: true, schemes: %w[http https] }
  validate :validate_tag_uniqueness, if: proc { level.to_s == "tag" }
  validate :validate_level_uniqueness, if: proc { LEVELS_WITH_EXPIRATION.include?(level) }

  scope :gold, -> { where(level: :gold) }
  scope :silver, -> { where(level: :silver) }
  scope :bronze, -> { where(level: :bronze) }
  scope :tag, -> { where(level: :tag) }
  scope :media, -> { where(level: :media) }
  scope :devrel, -> { where(level: :devrel) }

  scope :live, -> { where(status: :live) }
  scope :pending, -> { where(status: :pending) }

  scope :unexpired, -> { where("expires_at > ?", Time.current) }

  private

  def validate_tag_uniqueness
    return unless self.class.where(sponsorable: sponsorable, level: :tag).
      where("expires_at > ? AND id != ?", Time.current, id.to_i).exists?

    errors.add(:level, "The tag is already sponsored")
  end

  def validate_level_uniqueness
    return unless self.class.where(organization: organization).
      where("level IN (?) AND expires_at > ? AND id != ?", LEVELS_WITH_EXPIRATION, Time.current, id.to_i).exists?

    errors.add(:level, "You can have only one sponsorship of #{LEVELS_WITH_EXPIRATION.join(', ')}")
  end
end
