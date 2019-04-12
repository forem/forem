class Credit < ApplicationRecord

  attr_accessor :number_to_purchase

  belongs_to    :user
end
