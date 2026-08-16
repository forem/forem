# Shared gate for the Article/Comment/Reaction activity events sent to the
# Customer.io CDP. Adopters must implement #trackable_actor.
module ActivityTrackable
  extend ActiveSupport::Concern

  # A Concern dependency, not an `included` block: dependencies mix in first, so
  # this module stays ahead of Trackable's NotImplementedError stubs.
  include Trackable

  included do
    after_save :snapshot_trackable_changed_keys
    # Cleared after the commit hooks read it, or a later touch replays the
    # stale keys. Registers after Trackable's, which run first (Rails 7.1+).
    after_commit :clear_trackable_changed_keys
    after_rollback :clear_trackable_changed_keys
  end

  # Commit hooks can't read saved_changes here: Comment touches itself from an
  # after_save hook and touch calls changes_applied, collapsing the dirty state
  # to ["updated_at"]. touch doesn't fire after_save, so the snapshot survives.
  def trackable_changed_keys
    @trackable_changed_keys || saved_changes.keys
  end

  # Events are actor-keyed; the content's author rides along in properties.
  def trackable_actor
    raise NotImplementedError, "#{self.class.name} must implement #trackable_actor"
  end

  def trackable_user_ids
    [trackable_actor&.id]
  end

  private

  def snapshot_trackable_changed_keys
    @trackable_changed_keys = saved_changes.keys
  end

  def clear_trackable_changed_keys
    @trackable_changed_keys = nil
  end

  # Cheapest check first. Moderated actors stay silent for the same reason as
  # User#track_engagement!: a pruned Customer.io profile must not be resurrected.
  def trackable_events_skipped?
    return true unless Settings::General.customerio_cdp_enabled(subforem_id: Subforem.cached_default_id)

    actor = trackable_actor
    return true if actor.nil?
    return true unless actor.member?
    return true if actor.spam_or_suspended?

    super
  end
end
