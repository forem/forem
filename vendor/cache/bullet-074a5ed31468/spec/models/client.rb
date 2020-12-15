# frozen_string_literal: true

class Client < ActiveRecord::Base
  belongs_to :group

  has_many :relationships
  has_many :firms, through: :relationships
end
