require "administrate/field/base"

class TrustedUserField < Administrate::Field::Base
  def to_s
    data
  end
end
