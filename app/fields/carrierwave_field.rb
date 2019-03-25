require "administrate/field/base"

class CarrierwaveField < Administrate::Field::Base
  delegate :url, to: :data

  def to_s
    data
  end
end
