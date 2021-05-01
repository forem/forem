module FeedbackMessagesHelper
  OFFENDER_EMAIL_BODY = <<~HEREDOC.freeze
    Hello,

    It has been brought to our attention that you have violated the #{Settings::Community.community_name} Code of Conduct and/or Terms of Use.

    If this behavior continues, we may need to suspend your #{Settings::Community.community_name} account.

    If you think that there's been a mistake, please reply to this email and we will take another look.

    #{Settings::Community.community_name} Team
  HEREDOC

  REPORTER_EMAIL_BODY = <<~HEREDOC.freeze
    Hi there,
    Thank you for flagging content that may be in violation of the #{Settings::Community.community_name} Code of Conduct and/or our Terms of Use. We are looking into your report and will take appropriate action.
    We appreciate your help as we work to foster a positive and inclusive environment for all!
    #{Settings::Community.community_name} Team
  HEREDOC

  AFFECTED_EMAIL_BODY = <<~HEREDOC.freeze
    Hi there,

    We noticed some comments (made by others) on your post that violate the #{Settings::Community.community_name} Code of Conduct and/or our Terms of Use. We have zero tolerance for such behavior and are taking appropriate action.

    Thanks for being awesome, and please don't hesitate to email us with any questions! We welcome all feedback and ideas as we continue working to foster an open and inclusive community.

    #{Settings::Community.community_name} Team
  HEREDOC

  def offender_email_details
    body = format(OFFENDER_EMAIL_BODY)
    { subject: "#{Settings::Community.community_name} Code of Conduct Violation", body: body }.freeze
  end

  def reporter_email_details
    body = format(REPORTER_EMAIL_BODY)
    { subject: "#{Settings::Community.community_name} Report", body: body }.freeze
  end

  def affected_email_details
    body = format(AFFECTED_EMAIL_BODY)
    { subject: "Courtesy Notice from #{Settings::Community.community_name}", body: body }.freeze
  end
end
