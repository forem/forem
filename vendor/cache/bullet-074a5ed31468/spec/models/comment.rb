# frozen_string_literal: true

class Comment < ActiveRecord::Base
  belongs_to :post, inverse_of: :comments
  belongs_to :author, class_name: 'BaseUser'

  validates :post, presence: true
end
