class Announcement < ApplicationRecord
  belongs_to :broadcastable, polymorphic: true
end
