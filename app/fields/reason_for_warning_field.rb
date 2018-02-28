require "administrate/field/base"

class ReasonForWarningField < Administrate::Field::Base
  def to_s
    data
  end
end
