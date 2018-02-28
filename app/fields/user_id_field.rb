require "administrate/field/base"

class UserIdField < Administrate::Field::Base
  def find_user_id
    data
  end
end
