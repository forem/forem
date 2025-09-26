# app/workers/emails/enqueue_custom_batch_send_worker.rb
module Emails
  class EnqueueCustomBatchSendWorker
    include Sidekiq::Job

    sidekiq_options queue: :medium_priority, retry: 15

    BATCH_SIZE = Rails.env.production? ? 1000 : 10

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
                         executor.execute
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
          Rails.logger.debug("user_scope class: #{user_scope.class}")
          Rails.logger.debug("user_scope responds to find_in_batches: #{user_scope.respond_to?(:find_in_batches)}")
          user_scope.find_in_batches(batch_size: BATCH_SIZE) do |users_batch|
            # (Just printing the first ID so you can see progress.)
            p users_batch.first.id

            Emails::BatchCustomSendWorker.perform_async(
              users_batch.map(&:id),
              email.subject,
              email.body,
              email.type_of,
              email.id,
            )
          end
        end
      # As soon as this transaction block ends, Postgres automatically reverts
      # statement_timeout back to the previous session value (original_timeout).
      ensure
        # 6) Just to be safe, set ENV back and explicitly restore on the connection
        ENV["STATEMENT_TIMEOUT"] = original_timeout.to_s
        conn.execute("SET statement_timeout TO #{ENV.fetch('STATEMENT_TIMEOUT', nil)}")
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
