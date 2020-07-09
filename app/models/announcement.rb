class Announcement < ApplicationRecord
  has_one :broadcast, as: :broadcastable
end
