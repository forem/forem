# frozen_string_literal: true

class Mongoid::Category
  include Mongoid::Document

  field :name

  has_many :posts, class_name: 'Mongoid::Post'
  has_many :entries, class_name: 'Mongoid::Entry'
end
