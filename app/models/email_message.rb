class EmailMessage < Ahoy::Message
  belongs_to :feedback_message, optional: true

  # So far this is mostly used to be compatible with administrate gem,
  # which doesn't seem to play nicely with namespaces. But there could be other
  # reasons to define behavior here, similar to how we use the Tag model.
  def body_html_content
    doctype_index = content.index("<!DOCTYPE")
    closing_body_index = content.index("</body>") + 6
    content[doctype_index..closing_body_index]
  end

  def self.find_for_reports(feedback_message_ids)
    select(:to, :subject, :content, :utm_campaign, :feedback_message_id)
      .where(feedback_message_id: feedback_message_ids)
  end
end
