class Identity < ApplicationRecord
  NO_EMAIL_MSG = "No email found. Please relink your %<provider>s " \
                 "account to avoid errors.".freeze

  belongs_to :user

  scope :enabled, -> { where(provider: Authentication::Providers.enabled) }

  Authentication::Providers.available.each do |provider_name|
    scope provider_name, -> { where(provider: provider_name) }
  end

  validates :provider, inclusion: { in: Authentication::Providers.available.map(&:to_s) }
  validates :uid, :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }, if: proc { |identity|
                                                          identity.uid_changed? || identity.provider_changed?
                                                        }
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :provider }, if: proc { |identity|
                                                              identity.user_id_changed? || identity.provider_changed?
                                                            }

  # TODO: [@forem/oss] should this be transitioned to JSON?
  serialize :auth_data_dump

  # Builds an identity from OmniAuth's authentication payload
  def self.build_from_omniauth(provider)
    payload = provider.payload

    identity = find_or_initialize_by(
      provider: payload.provider,
      uid: payload.uid,
    )

    identity.assign_attributes(
      token: payload.credentials.token,
      secret: payload.credentials.secret,
      auth_data_dump: payload,
    )

    identity
  end

  def email
    auth_data_dump&.info&.email || format(NO_EMAIL_MSG, provider: provider)
  end
end
