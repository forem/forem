class OrganizationMembershipChallenge < ApplicationRecord
  belongs_to :organization_email_domain
  belongs_to :user

  validates :email, :otp_digest, :expires_at, presence: true

  def self.digest(value)
    key = Rails.application.key_generator.generate_key("organization-membership-otp", 32)
    OpenSSL::HMAC.hexdigest("SHA256", key, value)
  end

  def valid_otp?(otp)
    return false unless otp.match?(/\A[0-9]{8}\z/)

    ActiveSupport::SecurityUtils.secure_compare(otp_digest, self.class.digest("#{id}:#{otp}"))
  end
end
