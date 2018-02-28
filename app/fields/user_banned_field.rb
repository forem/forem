require "administrate/field/base"

class UserBannedField < Administrate::Field::Base
  def to_s
    data
  end
end
