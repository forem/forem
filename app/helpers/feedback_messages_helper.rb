module FeedbackMessagesHelper
  def offender_email_details
    body = <<~HEREDOC
      Hello,

      It has been brought to our attention that you have violated the #{SiteConfig.community_name} Code of Conduct and/or Terms of Use.

      If this behavior continues, we may need to suspend your #{SiteConfig.community_name} account.

      If you think that there's been a mistake, please reply to this email and we will take another look.

      #{SiteConfig.community_name} Team
    HEREDOC

    { subject: "#{SiteConfig.community_name} Code of Conduct Violation", body: body }.freeze
  end

  def affected_email_details
    body = <<~HEREDOC
      Hi there,

      We noticed some comments (made by others) on your post that violate the #{SiteConfig.community_name} Code of Conduct and/or our Terms of Use. We have zero tolerance for such behavior and are taking appropriate action.

      Thanks for being awesome, and please don't hesitate to email us with any questions! We welcome all feedback and ideas as we continue working to foster an open and inclusive community.

      #{SiteConfig.community_name} Team
    HEREDOC

    { subject: "Courtesy Notice from #{SiteConfig.community_name}", body: body }.freeze
  end
end
