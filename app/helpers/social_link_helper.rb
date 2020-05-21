module SocialLinkHelper
  def user_twitter_link(user)
    return "N/A" unless (username = user.twitter_username)

    link_to("@#{username}", "https://twitter.com/#{username}", target: "_blank", rel: :noopener)
  end

  def user_github_link(user)
    return "N/A" unless (username = user.github_username)

    link_to("@#{username}", "https://github.com/#{username}", target: "_blank", rel: :noopener)
  end
end
