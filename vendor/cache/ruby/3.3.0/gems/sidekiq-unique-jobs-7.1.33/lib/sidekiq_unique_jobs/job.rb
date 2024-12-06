# frozen_string_literal: true

module SidekiqUniqueJobs
  # Utility class to append uniqueness to the sidekiq job hash
  #
  # @author Mikael Henriksson <mikael@mhenrixon.com>
  module Job
    extend self

    # Adds timeout, expiration, lock_args, lock_prefix and lock_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def prepare(item)
      stringify_on_conflict_hash(item)
      add_lock_type(item)
      add_lock_timeout(item)
      add_lock_ttl(item)
      add_digest(item)
    end

    # Adds lock_args, lock_prefix and lock_digest to the sidekiq job hash
    # @return [Hash] the job hash
    def add_digest(item)
      add_lock_prefix(item)
      add_lock_args(item)
      add_lock_digest(item)

      item
    end

    private

    def stringify_on_conflict_hash(item)
      on_conflict = item[ON_CONFLICT]
      return unless on_conflict.is_a?(Hash)

      item[ON_CONFLICT] = on_conflict.deep_stringify_keys
    end

    def add_lock_ttl(item)
      item[LOCK_TTL] = SidekiqUniqueJobs::LockTTL.calculate(item)
    end

    def add_lock_timeout(item)
      item[LOCK_TIMEOUT] ||= SidekiqUniqueJobs::LockTimeout.calculate(item)
    end

    def add_lock_args(item)
      item[LOCK_ARGS] ||= SidekiqUniqueJobs::LockArgs.call(item)
    end

    def add_lock_digest(item)
      item[LOCK_DIGEST] ||= SidekiqUniqueJobs::LockDigest.call(item)
    end

    def add_lock_prefix(item)
      item[LOCK_PREFIX] ||= SidekiqUniqueJobs.config.lock_prefix
    end

    def add_lock_type(item)
      item[LOCK] ||= SidekiqUniqueJobs::LockType.call(item)
    end
  end
end
