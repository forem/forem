class CannedResponse < ApplicationRecord
  belongs_to :user, optional: true
  validates :type_of, :content_type, :content, :title, presence: true
end
