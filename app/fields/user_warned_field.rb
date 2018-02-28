require "administrate/field/base"

class UserWarnedField < Administrate::Field::Base
  def to_s
    data
  end
end
