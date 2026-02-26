# app/workers/emails/enqueue_custom_batch_send_worker.rb
module Emails
  class EnqueueCustomBatchSendWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_throttle(concurrency: { limit: 1 })

    sidekiq_options queue: :medium_priority, retry: 15, lock: :until_and_while_executing

    BATCH_SIZE = Rails.env.production? ? 1000 : 10

    def perform(email_id, min_id = nil, max_id = nil)
      batch_timeout_ms = ENV.fetch("EMAIL_BATCH_STATEMENT_TIMEOUT", 60_000).to_i

      # 1. Use User.transaction to PIN the connection. 
      # This guarantees that 'User', 'in_batches', and likely 'UserQueryExecutor' 
      # all share the exact same physical database connection for this block.
      User.transaction do
        # 2. Use SET LOCAL.
        # This applies the timeout strictly to this transaction. 
        # It automatically resets when the transaction commits/rollbacks.
        User.connection.execute("SET LOCAL statement_timeout TO #{batch_timeout_ms}")

        email = Email.find_by(id: email_id)
        return unless email

        if email.user_query.present?
          process_custom_query(email, min_id, max_id)
        else
          process_standard_scope(email, min_id, max_id)
        end
      end
    end

    private

    def process_custom_query(email, min_id = nil, max_id = nil)
      variables = extract_email_variables(email)
      executor = UserQueryExecutor.new(email.user_query, variables: variables)
      
      executor.each_id_batch(batch_size: 1000) do |id_batch|
        filtered_ids = id_batch
        filtered_ids = filtered_ids.select { |id| id >= min_id.to_i } if min_id
        filtered_ids = filtered_ids.select { |id| id <= max_id.to_i } if max_id

        next if filtered_ids.empty?

        # This query will now safely inherit the transaction's 60s timeout
        filtered_user_ids = User.email_eligible
                                .where(id: filtered_ids)
                                .pluck(:id)

        enqueue_batch(email, filtered_user_ids, "Custom Query")
      end
    end

    def process_standard_scope(email, min_id = nil, max_id = nil)
      base_scope = User.email_eligible

      base_scope = base_scope.where("users.id >= ?", min_id) if min_id
      base_scope = base_scope.where("users.id <= ?", max_id) if max_id

      user_scope = if email.audience_segment
                     base_scope.merge(email.audience_segment.users)
                   else
                     base_scope
                   end

      # in_batches yields relations. Because we are in a transaction,
      # it effectively reuses the same connection (and timeout) for every batch.
      user_scope.in_batches(of: BATCH_SIZE) do |relation|
        user_ids = relation.pluck(:id)
        enqueue_batch(email, user_ids, "Segment/Default")
      end
    end

    def enqueue_batch(email, user_ids, source_label)
      return if user_ids.empty?

      Rails.logger.info("Processing #{source_label} batch for email #{email.id}: #{user_ids.size} users")

      Emails::BatchCustomSendWorker.perform_async(
        user_ids,
        email.subject,
        email.body,
        email.type_of,
        email.id,
        email.default_from_name_based_on_type,
      )
    end

    def extract_email_variables(email)
      return {} unless email.respond_to?(:variables) && email.variables.present?
      JSON.parse(email.variables)
    rescue JSON::ParserError
      Rails.logger.warn("Invalid variables JSON in email #{email.id}")
      {}
    end
  end
end