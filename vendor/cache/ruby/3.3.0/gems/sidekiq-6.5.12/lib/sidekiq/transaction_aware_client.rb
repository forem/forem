# frozen_string_literal: true

require "securerandom"
require "sidekiq/client"

module Sidekiq
  class TransactionAwareClient
    def initialize(redis_pool)
      @redis_client = Client.new(redis_pool)
    end

    def push(item)
      # pre-allocate the JID so we can return it immediately and
      # save it to the database as part of the transaction.
      item["jid"] ||= SecureRandom.hex(12)
      AfterCommitEverywhere.after_commit { @redis_client.push(item) }
      item["jid"]
    end

    ##
    # We don't provide transactionality for push_bulk because we don't want
    # to hold potentially hundreds of thousands of job records in memory due to
    # a long running enqueue process.
    def push_bulk(items)
      @redis_client.push_bulk(items)
    end
  end
end

##
# Use `Sidekiq.transactional_push!` in your sidekiq.rb initializer
module Sidekiq
  def self.transactional_push!
    begin
      require "after_commit_everywhere"
    rescue LoadError
      Sidekiq.logger.error("You need to add after_commit_everywhere to your Gemfile to use Sidekiq's transactional client")
      raise
    end

    default_job_options["client_class"] = Sidekiq::TransactionAwareClient
    Sidekiq::JobUtil::TRANSIENT_ATTRIBUTES << "client_class"
    true
  end
end
