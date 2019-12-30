class CannedResponse < ApplicationRecord
  belongs_to :user
  validates :type_of, :content_type, :content, :title, presence: true
end
