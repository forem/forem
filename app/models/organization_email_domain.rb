class OrganizationEmailDomain < ApplicationRecord
  STATUSES = %w[pending approved rejected revoked].freeze
  # Consumer email providers cannot establish an organization affiliation.
  PUBLIC_DOMAINS = %w[gmail.com googlemail.com yahoo.com ymail.com hotmail.com outlook.com live.com
                      msn.com aol.com icloud.com me.com mac.com proton.me protonmail.com pm.me
                      mail.com gmx.com gmx.de fastmail.com hey.com yandex.com qq.com 163.com].freeze
  DOMAIN_PATTERN = /\A(?=.{1,253}\z)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}\z/

  belongs_to :organization
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_many :organization_membership_challenges, dependent: :destroy

  before_validation { self.domain = domain.to_s.strip.downcase }
  validates :domain, format: { with: DOMAIN_PATTERN }, uniqueness: { scope: :organization_id }
  validates :domain, exclusion: { in: PUBLIC_DOMAINS }
  validates :status, inclusion: { in: STATUSES }
  validate :domain_is_immutable, on: :update

  after_commit :purge_organization_cache

  scope :available, -> { where(status: "approved", enabled: true) }

  def available?
    status == "approved" && enabled?
  end

  # Hold the same lock as OTP consumption so revocation takes effect atomically.
  def review!(reviewer, decision)
    raise Pundit::NotAuthorizedError unless reviewer.super_admin?
    raise ArgumentError unless %w[approved rejected revoked].include?(decision)

    with_lock do
      update!(status: decision, enabled: false, reviewed_by: reviewer, reviewed_at: Time.current)
      organization_membership_challenges.where(consumed_at: nil).update_all(expires_at: Time.current)
      Note.create!(author: reviewer, noteable: organization, reason: "misc_note",
                   content: "Email domain #{domain}: #{decision}")
    end
  end

  private

  def domain_is_immutable
    errors.add(:domain, :invalid) if will_save_change_to_domain?
  end

  def purge_organization_cache
    BustCachePathWorker.perform_async(organization.path)
    EdgeCache::PurgeByKey.call(organization.path)
  end
end
