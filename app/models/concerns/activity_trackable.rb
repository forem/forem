# Shared gate for the content-activity events (article / comment / reaction)
# that DEV emits to the Customer.io CDP. Wraps Trackable with the suppressions
# every activity event needs, so the three adopting models do not each
# re-implement them:
#
#   * the customerio_cdp_enabled master switch, resolved via the default
#     subforem the way mailers do — the admin panel saves the setting
#     subforem-scoped, and model callbacks may run with no request context.
#   * non-human actors (community_bot / member_bot), matching the User sync.
#   * moderated accounts. User#track_engagement! already suppresses engagement
#     for spam/suspended users so a pruned Customer.io profile is not
#     resurrected by their activity; a comment or reaction from the same
#     account would resurrect it just as effectively, so activity events honour
#     the same rule. It also keeps the content-farm tail — 8% of authors
#     produce 61% of published articles — from dominating the event stream.
#
# The checks are ordered cheapest-first: the master switch is a cached Setting
# read, member? is an enum predicate, and only then do we reach
# spam_or_suspended?, which hits the authorizer.
#
# Adopters must implement #trackable_actor.
module ActivityTrackable
  extend ActiveSupport::Concern

  # Declared as a Concern dependency rather than included from an `included`
  # block: ActiveSupport::Concern mixes dependencies into the adopter *before*
  # this module, so ActivityTrackable lands nearer in the ancestor chain and
  # its overrides win. Including Trackable from `included` would invert that
  # and leave Trackable's NotImplementedError stubs in front.
  include Trackable

  included do
    # Registered from here, so it lands ahead of the adopting model's own
    # after_save hooks and observes the dirty state before they disturb it.
    after_save :snapshot_trackable_changed_keys

    # Discard the snapshot once the commit hooks for that save have run. This
    # registers after Trackable's (ActiveSupport::Concern mixes the dependency
    # in first) and Rails 7.1+ runs after_commit callbacks in definition order,
    # so the event callbacks still see it. Without this the snapshot outlives
    # its save: a later bare touch on the same instance — a comment touching
    # its article's last_comment_at — fires an update commit hook that would
    # re-read the create's keys and republish the article.
    after_commit :clear_trackable_changed_keys
    after_rollback :clear_trackable_changed_keys
  end

  # The change keys from the save that triggered the event. Commit hooks cannot
  # read saved_changes/previous_changes directly on these models: Comment
  # touches itself from an after_save hook (#expire_root_fragment) and touch
  # calls changes_applied, so by the time after_commit runs the dirty state has
  # collapsed to ["updated_at"] and every real edit looks like a no-op. touch
  # does not fire after_save, so a snapshot taken here survives it.
  def trackable_changed_keys
    @trackable_changed_keys || saved_changes.keys
  end

  # The User whose activity this is. Activity events are actor-keyed; the
  # content's author travels in properties instead (see each model's payload),
  # so downstream can still fan out on it.
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

  def trackable_events_skipped?
    return true unless Settings::General.customerio_cdp_enabled(subforem_id: Subforem.cached_default_id)

    actor = trackable_actor
    return true if actor.nil?
    return true unless actor.member?
    return true if actor.spam_or_suspended?

    super
  end
end
