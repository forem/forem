# frozen_string_literal: true

class Company < ActiveRecord::Base
  has_one :address
end
