class Identity < ApplicationRecord
  belongs_to :user
  has_many  :backup_data, as: :instance, class_name: "BackupData", dependent: :destroy
  validates :uid, :provider, presence: true
  validates :uid, uniqueness: { scope: :provider }, if: proc { |i| i.uid_changed? || i.provider_changed? }
  validates :user_id, uniqueness: { scope: :provider }, if: proc { |i| i.user_id_changed? || i.provider_changed? }
  validates :provider, inclusion: { in: %w[github twitter] }

  serialize :auth_data_dump

  def self.find_for_oauth(auth)
    find_or_create_by(uid: auth.uid, provider: auth.provider)
  end
end
