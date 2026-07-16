class WebpageReference < ApplicationRecord
  belongs_to :record, polymorphic: true
  belongs_to :linked_domain

  validates :url, presence: true
end
