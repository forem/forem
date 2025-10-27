# app/workers/emails/enqueue_custom_batch_send_worker.rb
module Emails
  class EnqueueCustomBatchSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    BATCH_SIZE = Rails.env.production? ? 500 : 10

    def perform(email_id)
      # 1) Remember the old ENV timeout (milliseconds)
      original_timeout = ENV.fetch("STATEMENT_TIMEOUT", 10_000).to_i

      # 2) Check out exactly one connection for the entire block
      # Use read-only database if available, otherwise fall back to main database
      ReadOnlyDatabaseService.with_connection do |conn|
        # 3) Ensure subsequent PG SETs inherit that same original timeout
        #    (in case some middleware or initializer reads ENV["STATEMENT_TIMEOUT"])
        ENV["STATEMENT_TIMEOUT"] = original_timeout.to_s
        conn.execute("SET statement_timeout TO #{original_timeout}")

        email = Email.find_by(id: email_id)
        return unless email

        user_scope = if email.user_query.present?
                       # Use custom user query for targeting
                       begin
                         # Extract variables from email if available
                         variables = extract_email_variables(email)
                         executor = UserQueryExecutor.new(email.user_query, variables: variables)
                         # Apply the same filtering as other paths to ensure proper notification settings and roles
                         executor.execute
                           .registered
                           .joins(:notification_setting)
                           .without_role(:suspended)
                           .without_role(:spam)
                           .where(notification_setting: { email_newsletter: true })
                           .where.not(email: "")
                       rescue StandardError => e
                         Rails.logger.error("UserQuery execution failed for email #{email.id}: #{e.message}")
                         User.none
                       end
                     elsif email.audience_segment
                       email.audience_segment.users
                         .registered
                         .joins(:notification_setting)
                         .without_role(:suspended)
                         .without_role(:spam)
                         .where(notification_setting: { email_newsletter: true })
                         .where.not(email: "")
                     else
                       User.registered
                         .joins(:notification_setting)
                         .without_role(:suspended)
                         .without_role(:spam)
                         .where(notification_setting: { email_newsletter: true })
                         .where.not(email: "")
                     end

        # 4) Now open a transaction. Everything inside here uses "SET LOCAL statement_timeout = 0"
        conn.transaction do
          # This sets statement_timeout=0 for *this* transaction only.
          # No matter how many queries ActiveRecord fires inside this block,
          # they all see infinite timeout.
          conn.execute("SET LOCAL statement_timeout TO 0")

          # 5) Run your batches inside the same transaction, so every SELECT is "no timeout"
          batch_count = 0
          total_users = 0

          user_scope.find_in_batches(batch_size: BATCH_SIZE) do |users_batch|
            batch_count += 1

            # Skip empty batches
            next if users_batch.empty?

            # Validate we have valid user IDs
            user_ids = users_batch.map(&:id).compact
            next if user_ids.empty?

            total_users += user_ids.size

            Rails.logger.info("Processing email batch #{batch_count} for email #{email.id}: #{user_ids.size} users (first ID: #{user_ids.first})")

            begin
              Emails::BatchCustomSendWorker.perform_async(
                user_ids,
                email.subject,
                email.body,
                email.type_of,
                email.id,
              )
            rescue StandardError => e
              Rails.logger.error("Failed to enqueue batch #{batch_count} for email #{email.id}: #{e.message}")
              # Continue processing other batches even if one fails
              next
            end
          end

          Rails.logger.info("Completed email processing for email #{email.id}: #{batch_count} batches, #{total_users} total users")
        end
      # As soon as this transaction block ends, Postgres automatically reverts
      # statement_timeout back to the previous session value (original_timeout).
      ensure
        # 6) Just to be safe, set ENV back and explicitly restore on the connection
        ENV["STATEMENT_TIMEOUT"] = original_timeout.to_s
        conn.execute("SET statement_timeout TO #{ENV.fetch('STATEMENT_TIMEOUT', 10_000)}")
      end
    end
  end

  private

  def extract_email_variables(email)
    variables = {}

    # Extract variables from email's variables field if it exists
    if email.respond_to?(:variables) && email.variables.present?
      begin
        variables.merge!(JSON.parse(email.variables))
      rescue JSON::ParserError
        Rails.logger.warn("Invalid variables JSON in email #{email.id}")
      end
    end

    variables
  end
end
