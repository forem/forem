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
end
