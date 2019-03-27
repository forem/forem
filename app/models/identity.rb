class Identity < ApplicationRecord
  belongs_to :user
  validates :uid, :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }
  # validates :provider, uniqueness: { scope: :uid }
  validates :user_id, uniqueness: { scope: :provider }
  validates :provider, inclusion: { in: %w[github twitter] }

  serialize :auth_data_dump

  def self.find_for_oauth(auth)
    find_or_create_by(uid: auth.uid, provider: auth.provider)
  end
end
