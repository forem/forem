module Trackable
  extend ActiveSupport::Concern

  DEFAULT_EXCLUDED_KEYS = %w[created_at updated_at].freeze

  def trackable_user_ids
    raise NotImplementedError, "#{self.class.name} must implement #trackable_user_ids"
  end

  def trackable_payload
    as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)
  end
end
