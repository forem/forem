module FeedbackMessagesHelper
  def offender_email_details
    body = <<~HEREDOC
      Hello,

      It has been brought to our attention that you have violated the #{ApplicationConfig['COMMUNITY_NAME']} Code of Conduct and/or Terms of Use.

      If this behavior continues, we may need to suspend your #{ApplicationConfig['COMMUNITY_NAME']} account.

      If you think that there's been a mistake, please reply to this email and we will take another look.

      #{ApplicationConfig['COMMUNITY_NAME']} Team
    HEREDOC

    { subject: "#{ApplicationConfig['COMMUNITY_NAME']} Code of Conduct Violation", body: body }.freeze
  end

  def reporter_email_details
    body = <<~HEREDOC
      Hi there,

      Thank you for flagging content that may be in violation of the #{ApplicationConfig['COMMUNITY_NAME']} Code of Conduct and/or our Terms of Use. We are looking into your report and will take appropriate action.

      We appreciate your help as we work to foster a positive and inclusive environment for all!

      #{ApplicationConfig['COMMUNITY_NAME']} Team
    HEREDOC

    { subject: "#{ApplicationConfig['COMMUNITY_NAME']} Report", body: body }.freeze
  end

  def affected_email_details
    body = <<~HEREDOC
      Hi there,

      We noticed some comments (made by others) on your post that violate the #{ApplicationConfig['COMMUNITY_NAME']} Code of Conduct and/or our Terms of Use. We have zero tolerance for such behavior and are taking appropriate action.

      Thanks for being awesome, and please don't hesitate to email us with any questions! We welcome all feedback and ideas as we continue working to foster an open and inclusive community.

      #{ApplicationConfig['COMMUNITY_NAME']} Team
    HEREDOC

    { subject: "Courtesy Notice from #{ApplicationConfig['COMMUNITY_NAME']}", body: body }.freeze
  end
end
