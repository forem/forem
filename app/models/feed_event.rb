class FeedEvent < ApplicationRecord
  belongs_to :article
  belongs_to :user, optional: true

  enum category: {
    impression: 0,
    click: 1
  }

  CONTEXT_TYPE_HOME = "home".freeze
  CONTEXT_TYPE_SEARCH = "search".freeze
  CONTEXT_TYPE_TAG = "tag".freeze
  VALID_CONTEXT_TYPES = [
    CONTEXT_TYPE_HOME,
    CONTEXT_TYPE_SEARCH,
    CONTEXT_TYPE_TAG,
  ].freeze

  validates :context_type, inclusion: { in: VALID_CONTEXT_TYPES }, presence: true
end
