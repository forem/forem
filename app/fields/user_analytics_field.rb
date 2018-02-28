require "administrate/field/base"

class UserAnalyticsField < Administrate::Field::Base
  def to_s
    data
  end
end
