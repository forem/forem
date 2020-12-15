# frozen_string_literal: true

class User < ActiveRecord::Base
  has_one :submission
  belongs_to :category
end
