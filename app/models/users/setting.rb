module Users
   class Setting < ApplicationRecord
     self.table_name_prefix = "users_"
   end
 end
