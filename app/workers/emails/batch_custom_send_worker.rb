module Emails
  class BatchCustomSendWorker
    include Sidekiq::Job
    include Sidekiq::Throttled::Job

    sidekiq_options queue: :low_priority, lock: :until_and_while_executing
    sidekiq_throttle(concurrency: { limit: ENV.fetch("EMAIL_BATCH_CONCURRENCY_LIMIT", 5).to_i })

    def perform(user_ids, subject, content, type_of, email_id, from_name = nil)
      user_ids = user_ids.map(&:to_i)

      # Optimized: Load all users in one query instead of N queries (avoids N+1)
      # Only select the columns the mailer actually uses (id, email, name, username)
      # to reduce memory and transfer overhead for large batches.
      users_by_id = User.where(id: user_ids)
                        .select(:id, :email, :name, :username)
                        .index_by(&:id)

      # Bulk check: skip users who already received a non-test email for this email_id.
      # Uses a subquery with DISTINCT ON to get the most recent message per user,
      # then filters out [TEST] subjects — all in a single SQL round-trip.
      already_sent_user_ids = if subject.start_with?("[TEST] ")
                                Set.new
                              else
                                sql = Ahoy::Message.sanitize_sql_array([<<~SQL.squish, user_ids, email_id])
                                  SELECT user_id FROM (
                                    SELECT DISTINCT ON (user_id) user_id, subject
                                    FROM ahoy_messages
                                    WHERE user_id IN (?) AND email_id = ?
                                    ORDER BY user_id, id DESC
                                  ) recent_messages
                                  WHERE subject NOT LIKE '[TEST] %'
                                SQL
                                Ahoy::Message.connection.select_values(sql).map(&:to_i).to_set
                              end

      user_ids.each do |id|
        user = users_by_id[id]
        next unless user
        next if already_sent_user_ids.include?(id)

        CustomMailer
          .with(
            user: user,
            subject: subject,
            content: content,
            type_of: type_of,
            email_id: email_id,
            from_name: from_name
          )
          .custom_email
          .deliver_now
      rescue StandardError => e
        Rails.logger.error("Error sending email to user with id: #{id}. Error: #{e.message}")
      end
    end
  end
end
