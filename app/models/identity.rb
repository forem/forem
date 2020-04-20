class Identity < ApplicationRecord
  belongs_to :user
  has_many  :backup_data, as: :instance, class_name: "BackupData", dependent: :destroy

  validates :uid, :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }, if: proc { |identity| identity.uid_changed? || identity.provider_changed? }
  validates :user_id, presence: true
  validates :user_id, uniqueness: { scope: :provider }, if: proc { |identity| identity.user_id_changed? || identity.provider_changed? }

  # TODO: [thepracticaldev/oss] put the providers somewhere else
  validates :provider, inclusion: { in: %w[github twitter] }

  # TODO: [thepracticaldev/oss] should this be transitioned to JSON?
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
end
