require "administrate/field/base"

class NameOfUserField < Administrate::Field::Base
  def to_s
    data
  end
end
