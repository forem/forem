module ProfileHelper
  def social_authentication_links_for(user)
    # Returns a Hash containing URLs for social authentication providers
    # Currently supported: GitHub, Twitter, Facebook
    user_identities = user.identities_enabled
    return {} if user_identities.blank?

    urls = user_identities.pluck(:auth_data_dump).each_with_object({}) do |data, hash|
      # TODO: [@jacobherrington] There are some examples in production of the `auth_data_dump` value being
      # `nil`. This appears to be the case around ~0.6% of the time.
      if (data_urls = data&.dig(:info, :urls))
        hash.merge!(data_urls)
      end
    end

    { github: urls["GitHub"], twitter: urls["Twitter"], facebook: urls["Facebook"] }.compact
  end
end
