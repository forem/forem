class UserRole < ApplicationRecord
  self.table_name = "users_roles"

  belongs_to :user
  belongs_to :role
end
