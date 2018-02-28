require "administrate/field/base"

class UserScholarField < Administrate::Field::Base
  def to_s
    data
  end
end
