module FeedbackMessagesHelper
  def offender_email_details
    body = I18n.t("helpers.feedback_messages_helper.offender", community: Settings::Community.community_name)
    {
      subject: I18n.t("helpers.feedback_messages_helper.code_of_conduct_violation",
                      community: Settings::Community.community_name), body: body
    }.freeze
  end

  def reporter_email_details
    body = I18n.t("helpers.feedback_messages_helper.reporter", community: Settings::Community.community_name)
    { subject: I18n.t("helpers.feedback_messages_helper.report", community: Settings::Community.community_name),
      body: body }.freeze
  end

  def affected_email_details
    body = I18n.t("helpers.feedback_messages_helper.affected", community: Settings::Community.community_name)
    {
      subject: I18n.t("helpers.feedback_messages_helper.courtesy_notice_from",
                      community: Settings::Community.community_name), body: body
    }.freeze
  end
end
