require "administrate/field/base"

class ReasonForBanField < Administrate::Field::Base
  def to_s
    data
  end
end
