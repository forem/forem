class ContextNotification < ApplicationRecord
  belongs_to :context, polymorphic: true

  validates :action, presence: true, inclusion: { in: %w[Published] }
  validates :context_type, presence: true, inclusion: { in: %w[Article] }
  validates :context_id, uniqueness: { scope: %i[context_type action] }
end
