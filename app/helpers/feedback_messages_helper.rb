module FeedbackMessagesHelper
  def offender_email_details
    body = <<~HEREDOC
      Hi [*USERNAME*],

      All dev.to members are expected to help foster a welcoming environment for the community and abide by our terms and conditions of use. It's been brought to our attention that you may have violated our code of conduct.  If this behavior continues, we will need to ban your posting privileges on dev.to.

      If you think there's been a mistake, please reply to this email and we'll sort it out.

      Thanks,
      dev.to team
    HEREDOC
    {
      subject: "dev.to Status Update",
      body: body
    }.freeze
  end

  def reporter_email_details
    body = <<~HEREDOC
      Hi [*USERNAME*],

      We wanted to say thank you for flagging a [*comment/post*] that was in violation of the dev.to code of conduct and terms of service. Your action has helped us continue our work of fostering an open and welcoming community.

      We've also removed the offending posts and reached out to the offender(s).

      Thanks again for being a great part of the community.

      PBJ
    HEREDOC
    {
      subject: "dev.to Status Update",
      body: body
    }.freeze
  end

  def victim_email_details
    body = <<~HEREDOC
      Hi [*USERNAME*],

      We noticed some comments (made by others) on your [*post/comment*] that violated the dev.to code of conduct. We want you to know that we have zero tolerance for such behavior, and have removed the offending posts and reached out to the offender(s).

      Thanks for being awesome and please don't hesitate to email us with any questions.  We welcome all feedback and ideas as we continue our work of fostering an open and welcoming community.

      PBJ
    HEREDOC
    {
      subject: "Courtesy Notice from dev.to",
      body: body
    }.freeze
  end
end
