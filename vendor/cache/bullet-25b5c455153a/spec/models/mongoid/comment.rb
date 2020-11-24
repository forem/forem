# frozen_string_literal: true

class Mongoid::Comment
  include Mongoid::Document

  field :name

  belongs_to :post, class_name: 'Mongoid::Post'
end
