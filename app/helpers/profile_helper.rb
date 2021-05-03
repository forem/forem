module ProfileHelper
  def social_authentication_links_for(user)
    # Returns a Hash containing URLs for social authentication providers
    # Currently supported: GitHub, Twitter, Facebook
    user_identities = user.identities_enabled
    return {} if user_identities.blank?

    urls = user_identities.pluck(:auth_data_dump).each_with_object({}) do |data, hash|
      if (data_urls = data.dig(:info, :urls))
        hash.merge!(data_urls)
      end
    end

    { github: urls["GitHub"], twitter: urls["Twitter"], facebook: urls["Facebook"] }.compact
  end
end
