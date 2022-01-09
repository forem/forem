module FeedbackMessagesHelper
  def offender_email_details
    body = I18n.t("helpers.feedback_messages_helper.offender.body", community: Settings::Community.community_name)
    {
      subject: I18n.t("helpers.feedback_messages_helper.offender.subject",
                      community: Settings::Community.community_name), body: body
    }.freeze
  end

  def reporter_email_details
    body = I18n.t("helpers.feedback_messages_helper.reporter.body", community: Settings::Community.community_name)
    {
      subject: I18n.t("helpers.feedback_messages_helper.reporter.subject",
                      community: Settings::Community.community_name), body: body
    }.freeze
  end

  def affected_email_details
    body = I18n.t("helpers.feedback_messages_helper.affected.body", community: Settings::Community.community_name)
    {
      subject: I18n.t("helpers.feedback_messages_helper.affected.subject",
                      community: Settings::Community.community_name), body: body
    }.freeze
  end
end
