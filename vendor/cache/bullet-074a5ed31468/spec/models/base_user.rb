# frozen_string_literal: true

class BaseUser < ActiveRecord::Base
  has_many :comments
  has_many :posts
  belongs_to :newspaper
end
