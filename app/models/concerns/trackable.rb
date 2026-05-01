module Trackable
  extend ActiveSupport::Concern

  DEFAULT_EXCLUDED_KEYS = %w[created_at updated_at].freeze
  TOUCH_ONLY_KEYS       = %w[updated_at engaged_at].freeze

  included do
    after_commit :enqueue_trackable_event_created,   on: :create
    after_commit :enqueue_trackable_event_updated,   on: :update
    after_commit :enqueue_trackable_event_destroyed, on: :destroy

    before_destroy :snapshot_trackable_user_ids
    after_rollback :clear_trackable_user_id_snapshot, on: :destroy
  end

  def trackable_user_ids
    raise NotImplementedError, "#{self.class.name} must implement #trackable_user_ids"
  end

  def trackable_payload
    as_json.except(*Trackable::DEFAULT_EXCLUDED_KEYS)
  end

  private

  def enqueue_trackable_event_created
    enqueue_trackable_event("#{model_name.param_key}_created")
  end

  def enqueue_trackable_event_updated
    return if touch_only_change?

    enqueue_trackable_event("#{model_name.param_key}_updated")
  end

  def enqueue_trackable_event_destroyed
    enqueue_trackable_event(
      "#{model_name.param_key}_destroyed",
      user_ids: @_trackable_destroyed_user_ids || Array.wrap(trackable_user_ids).compact.uniq,
    )
  end

  def enqueue_trackable_event(event_name, user_ids: nil, properties_override: {})
    user_ids = Array.wrap(user_ids || trackable_user_ids).compact.uniq
    return if user_ids.empty?

    properties = trackable_payload.merge(properties_override)
    timestamp  = Time.current.iso8601

    Trackable::Registry.active_with_names.each do |adapter_name, _adapter|
      Trackable::DispatchWorker.perform_async(
        adapter_name.to_s, event_name, user_ids, properties, timestamp,
      )
    end
  end

  def snapshot_trackable_user_ids
    @_trackable_destroyed_user_ids = Array.wrap(trackable_user_ids).compact.uniq
  end

  def clear_trackable_user_id_snapshot
    @_trackable_destroyed_user_ids = nil
  end

  def touch_only_change?
    (previous_changes.keys - Trackable::TOUCH_ONLY_KEYS).empty?
  end
end
