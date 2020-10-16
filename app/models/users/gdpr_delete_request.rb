module Users
  class GdprDeleteRequest < ApplicationRecord
    def self.table_name_prefix
      "users_"
    end
  end
end
