class Sponsorship < ApplicationRecord
  LEVELS = %w[gold silver bronze tag media devrel].freeze
  METAL_LEVELS = %w[gold silver bronze].freeze
  STATUSES = %w[none pending live].freeze
  SPONSORABLE_TYPES = %w[Tag ActsAsTaggableOn::Tag].freeze
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

  validates :level, presence: true, inclusion: { in: LEVELS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :url, url: { allow_blank: true, no_local: true, schemes: %w[http https] }
  validates :featured_number, presence: true
  validates :sponsorable_type, inclusion: {
    in: SPONSORABLE_TYPES,
    allow_blank: true,
    message: I18n.t("models.sponsorship.invalid_type")
  }

  validate :validate_tag_uniqueness, if: proc { level.to_s == "tag" }
  validate :validate_level_uniqueness, if: proc { METAL_LEVELS.include?(level) }

  LEVELS.each do |level|
    scope level, -> { where(level: level) }
  end

  scope :live, -> { where(status: :live) }
  scope :pending, -> { where(status: :pending) }

  scope :unexpired, -> { where("expires_at > ?", Time.current) }

  private

  def validate_tag_uniqueness
    return unless self.class.where(sponsorable: sponsorable, level: :tag)
      .exists?(["expires_at > ? AND id != ?", Time.current, id.to_i])

    errors.add(:level, I18n.t("models.sponsorship.already_sponsored"))
  end

  def validate_level_uniqueness
    return unless self.class.where(organization: organization)
      .exists?(["level IN (?) AND expires_at > ? AND id != ?", METAL_LEVELS, Time.current, id.to_i])

    levels = METAL_LEVELS.map { |l| I18n.t("models.sponsorship.level.#{l}") }.to_sentence(locale: I18n.locale)
    errors.add(:level, I18n.t("models.sponsorship.only_one_level", levels: levels))
  end
end
