# frozen_string_literal: true

class Document < ActiveRecord::Base
  has_many :children, class_name: 'Document', foreign_key: 'parent_id'
  belongs_to :parent, class_name: 'Document', foreign_key: 'parent_id'
  belongs_to :author
end
