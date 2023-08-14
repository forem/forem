class FeedEvent < ApplicationRecord
  belongs_to :article
  belongs_to :user, optional: true

  enum category: {
    impression: 0,
    click: 1
  }
end
