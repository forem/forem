module Favorites
  # Marks an Article or Comment as a favorite. A record can only be marked a
  # favorite once. Community leaders spend a time-bound allowance, and everyone
  # else spends persisted credits earned by having their own content favorited.
  class Create
    Result = Struct.new(:success?, :favoritable, :error, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(favoritable:, user:)
      @favoritable = favoritable
      @user = user
    end

    def call
      error = precheck_error || claim
      return failure(error) if error

      favoritable.reload
      log_audit
      grant_earned_favorite
      Result.new(success?: true, favoritable: favoritable)
    end

    private

    attr_reader :user, :favoritable

    def precheck_error
      return :already_favorited if favoritable.favorited_by_user_id.present?
      return :self_favorite if favoritable.user_id == user.id
      return :ineligible unless eligible?

      nil
    end

    # Claims a favorite against the user's allowance in one transaction.
    # Update order avoids deadlocks with other transactions that also lock in
    # this order (see counter_culture callbacks in Reaction and Comment).
    def claim
      error = nil

      ActiveRecord::Base.transaction do
        if claim_favoritable.zero?
          error = :already_favorited
          raise ActiveRecord::Rollback
        end

        unless can_afford_claim?
          error = :no_allowance
          raise ActiveRecord::Rollback
        end
      end

      error
    end

    # Claims the favorite for the user if still unclaimed in one query.
    # Returns 1 if successful or 0 otherwise.
    def claim_favoritable
      favoritable.class
        .where(id: favoritable.id, favorited_by_user_id: nil)
        .update_all(favorited_by_user_id: user.id, favorited_at: Time.current)
    end

    # Checks that the user's favorite allowance can cover the favorite just
    # made, and updates it for regular users.
    # Returns true on valid and successful spend, or false otherwise.
    def can_afford_claim?
      return spend_earned_favorite == 1 unless user.community_leader?

      # For community leaders, lock to serialize the allowance check for the
      # rest of the claim transaction.
      user.lock!
      !user.favorite_allowance.negative?
    end

    # Checks and decrements earned favorites safely in one query. Touches the
    # row so the spender's cached payload reflects the new balance.
    # Returns 1 if successful or 0 otherwise.
    def spend_earned_favorite
      User.where(id: user.id)
        .where(earned_favorites_count: 1..)
        .update_all("earned_favorites_count = earned_favorites_count - 1, updated_at = NOW()")
    end

    def grant_earned_favorite
      User.update_counters(favoritable.user_id, earned_favorites_count: 1, touch: true)
    end

    def eligible?
      case favoritable
      when Article then favoritable.published?
      when Comment then !favoritable.deleted?
      else false
      end
    end

    def log_audit
      Audit::Logger.log(:moderator, user,
                        "action" => "favorite",
                        "favoritable_type" => favoritable.class.name,
                        "favoritable_id" => favoritable.id,
                        "target_user_id" => favoritable.user_id)
    end

    def failure(error)
      Result.new(success?: false, favoritable: favoritable, error: error)
    end
  end
end
