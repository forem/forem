class EmailMessage < Ahoy::Message
  belongs_to :feedback_message, optional: true

  def html_content
    html_index = content.index("<html")
    closing_html_index = content.index("</html>") + 7
    content[html_index..closing_html_index]
  end

  def self.find_for_reports(feedback_message_ids)
    select(:to, :subject, :content, :utm_campaign, :feedback_message_id)
      .where(feedback_message_id: feedback_message_ids)
  end

  def self.fast_destroy_old_retained_email_deliveries(destroy_before_timestamp = 3.months.ago)
    # We remove email delivery records periodically, except some we retain long term.
    # We generally want to retain emails directly sent by human admins.
    # The only email currently sent manually are those that are tied directly to a feedback message.
    sql = <<~SQL
      DELETE FROM ahoy_messages
      WHERE ahoy_messages.id IN (
        SELECT ahoy_messages.id
        FROM ahoy_messages
        WHERE sent_at < ? AND feedback_message_id IS NULL
        LIMIT 50000
      )
    SQL

    email_sql = EmailMessage.sanitize_sql([sql, destroy_before_timestamp])

    BulkSqlDelete.delete_in_batches(email_sql)
  end
end
