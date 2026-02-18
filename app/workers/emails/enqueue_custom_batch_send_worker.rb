# app/workers/emails/enqueue_custom_batch_send_worker.rb
module Emails
  class EnqueueCustomBatchSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15, lock: :until_and_while_executing

    BATCH_SIZE = Rails.env.production? ? 1000 : 10 # Increased batch size is safe with pluck

    def perform(email_id, min_id = nil, max_id = nil)
      # Use a longer timeout for batch operations to avoid query cancellations.
      # Batch processing can take time, especially with large datasets and complex queries.
      # Default read-only DB timeout is 30s, but we use 60s for batch operations.
      batch_timeout_ms = ENV.fetch("EMAIL_BATCH_STATEMENT_TIMEOUT", 60_000).to_i

      ReadOnlyDatabaseService.with_connection do |conn|
        # Set timeout for this connection session to handle long-running batch queries
        conn.execute("SET statement_timeout TO #{batch_timeout_ms}")

        email = Email.find_by(id: email_id)
        return unless email

        if email.user_query.present?
          process_custom_query(email, min_id, max_id)
        else
          process_standard_scope(email, min_id, max_id)
        end
        
        # Reset timeout to default when done (good practice for connection reuse)
        conn.execute("RESET statement_timeout")
      end
    end

    private

    def process_custom_query(email, min_id = nil, max_id = nil)
      variables = extract_email_variables(email)
      executor = UserQueryExecutor.new(email.user_query, variables: variables)
      
      executor.each_id_batch(batch_size: 1000) do |id_batch|
        # Optional: Apply ID range filtering in Ruby for custom query results
        filtered_ids = id_batch
        filtered_ids = filtered_ids.select { |id| id >= min_id.to_i } if min_id
        filtered_ids = filtered_ids.select { |id| id <= max_id.to_i } if max_id

        next if filtered_ids.empty?

        # Load ONLY ids, don't instantiate User objects if possible
        filtered_user_ids = User.where(id: filtered_ids)
                                .registered
                                .joins(:notification_setting)
                                .without_role(:suspended)
                                .without_role(:spam)
                                .where(notification_setting: { email_newsletter: true })
                                .where.not(email: "")
                                .pluck(:id)

        enqueue_batch(email, filtered_user_ids, "Custom Query")
      end
    end

    def process_standard_scope(email, min_id = nil, max_id = nil)
      # Build the relation
      base_scope = User.registered
                       .joins(:notification_setting)
                       .without_role(:suspended)
                       .without_role(:spam)
                       .where(notification_setting: { email_newsletter: true })
                       .where.not(email: "")

      # Apply ID range filtering at the DB level for standard scopes
      base_scope = base_scope.where("users.id >= ?", min_id) if min_id
      base_scope = base_scope.where("users.id <= ?", max_id) if max_id

      user_scope = if email.audience_segment
                     base_scope.merge(email.audience_segment.users)
                   else
                     base_scope
                   end

      # OPTIMIZED: Use in_batches + pluck to avoid loading User models
      user_scope.in_batches(of: BATCH_SIZE) do |relation|
        # relation is an ActiveRecord::Relation for the batch (e.g. "WHERE id BETWEEN 1 and 1000")
        # .pluck(:id) executes "SELECT id FROM ..." directly
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