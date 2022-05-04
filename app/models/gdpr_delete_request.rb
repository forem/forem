class GDPRDeleteRequest < ApplicationRecord
  validates :email, :user_id, presence: true

  def self.table_name_prefix
    "users_"
  end
end
