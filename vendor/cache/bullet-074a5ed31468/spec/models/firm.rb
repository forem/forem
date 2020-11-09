# frozen_string_literal: true

class Firm < ActiveRecord::Base
  has_many :relationships
  has_many :clients, through: :relationships
  has_many :groups, through: :clients
end
