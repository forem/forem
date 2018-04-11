require "administrate/field/base"

class TagModeratorsField < Administrate::Field::Base
  def to_s
    data.join(",")
  end
end
