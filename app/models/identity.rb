class Identity < ApplicationRecord
  belongs_to :user
  validates_presence_of :uid, :provider
  validates_uniqueness_of :uid, scope: :provider
  validates_uniqueness_of :provider, scope: :uid
  validates_uniqueness_of :user_id, scope: :provider
  validates :provider, inclusion: { in: %w(github twitter) }

  serialize :auth_data_dump

  def self.find_for_oauth(auth)
    find_or_create_by(uid: auth.uid, provider: auth.provider)
  end
end
