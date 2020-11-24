# frozen_string_literal: true

class City < ActiveRecord::Base
  belongs_to :country
end
