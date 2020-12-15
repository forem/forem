# frozen_string_literal: true

class Category < ActiveRecord::Base
  has_many :posts, inverse_of: :category
  has_many :entries

  has_many :users

  def draft_post
    posts.draft.first_or_create
  end
end
