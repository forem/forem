module Users
  # Grants the bootstrap roles (creator, super_admin, trusted) to at most one
  # user, across the email and OAuth signup paths.
  #
  # Callers read `Settings::General.waiting_on_first_user` before they save the
  # new user (on a fresh database the setting is unset and falls back to
  # `!User.exists?`, which is false once the user is saved) and call this only
  # when that value was true.  That value can be stale: a concurrent signup may
  # have claimed the grant since.  So this service takes a transaction-level
  # advisory lock and re-checks the stored state before it grants anything:
  #
  #   * a stored `false` row means the grant was already claimed;
  #   * a stored `true` row means the instance is explicitly waiting;
  #   * no row means the grant goes to the earliest user only.
  #
  # The roles, the stored `false` and the mascot account are written in the
  # same transaction, so a signup that rolls back (or a mascot creation that
  # fails) does not consume the grant.  The lock is held until the outermost
  # transaction commits, so a second claimant sees the first claimant's
  # committed `false`.  The settings cache is cleared again if the outermost
  # transaction rolls back, so a read of the uncommitted values cannot outlive
  # the rollback.
  class ClaimFirstUser
    LOCK_KEY = Zlib.crc32("forem:users:claim_first_user")
    SETTING = "waiting_on_first_user".freeze

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    # Returns true if this user received the first-user roles.
    def call
      return false unless user.persisted?

      ActiveRecord::Base.transaction(requires_new: true) do
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{LOCK_KEY})")
        next false unless eligible?

        user.add_role(:creator)
        user.add_role(:super_admin)
        user.add_role(:trusted)
        mark_claimed!
        create_mascot_account
        true
      end
    end

    private

    attr_reader :user

    def eligible?
      stored = setting_rows.map(&:value)
      return false if stored.any? { |value| !value.nil? && !boolean(value) }
      return true if stored.any? { |value| boolean(value) }

      !User.where(User.arel_table[:id].lt(user.id)).exists?
    end

    def mark_claimed!
      setting_rows.each { |row| row.update!(value: false) }
      Settings::General.waiting_on_first_user = false
      Settings::General.clear_cache
      # Settings::Base clears its cache after commit only.  Callbacks on this
      # nested transaction move to the parent, so this runs if any enclosing
      # transaction (e.g. the OAuth signup) rolls back.
      ActiveRecord::Base.current_transaction.after_rollback { Settings::General.clear_cache }
    end

    def create_mascot_account
      return if Settings::General.mascot_user_id.present?

      Users::CreateMascotAccount.call
    end

    def setting_rows
      Settings::General.unscoped.where(var: SETTING).to_a
    end

    def boolean(value)
      value.in?(["true", "1", 1, true])
    end
  end
end
