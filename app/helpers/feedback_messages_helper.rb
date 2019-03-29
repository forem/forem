module FeedbackMessagesHelper
  def offender_email_details
    body = <<~HEREDOC
      Hi,

      All DEV members are expected to help foster a welcoming environment for the community. It's been brought to our attention that you have violated our code of conduct and/or terms of use. If this behavior continues, we will need to ban your posting privileges on dev.to.

      If you think there's been a mistake, please reply to this email and we'll sort it out.

      Thanks,
      DEV team
    HEREDOC

    { subject: "DEV Code of Conduct Violation", body: body }.freeze
  end

  def reporter_email_details
    body = <<~HEREDOC
      Hi!,

      We wanted to say thank you for flagging content that may be in violation of the DEV code of conduct and/or terms of use. We'll be looking into your report.

      Thank you for the support.

      DEV Team
    HEREDOC

    { subject: "DEV Report", body: body }.freeze
  end

  def affected_email_details
    body = <<~HEREDOC
      Hi,

      We noticed some comments (made by others) on your post that violated the DEV code of conduct and/or terms of use. We want you to know that we have zero tolerance for such behavior and are taking appropriate action.

      Thanks for being awesome and please don't hesitate to email us with any questions.  We welcome all feedback and ideas as we continue our work of fostering an open and welcoming community.

      DEV Team
    HEREDOC

    { subject: "Courtesy Notice from DEV", body: body }.freeze
  end
end
