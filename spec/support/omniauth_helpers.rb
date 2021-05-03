module OmniauthHelpers
  OMNIAUTH_DEFAULT_FAILURE_HANDLER = OmniAuth.config.on_failure

  OMNIAUTH_INFO = OmniAuth::AuthHash::InfoHash.new(
    first_name: "fname",
    last_name: "lname",
    location: "location,state,country",
    name: "fname lname",
    nickname: "fname.lname",
    email: "yourname@email.com",
    verified: true,
  )

  OMNIAUTH_EXTRA_INFO = OmniAuth::AuthHash::InfoHash.new(
    raw_info: OmniAuth::AuthHash::InfoHash.new(
      email: "yourname@email.com",
      first_name: "fname",
      gender: "female",
      id: "123456",
      last_name: "lname",
      link: "http://www.facebook.com/url&#8221",
      lang: "fr",
      locale: "en_US",
      name: "fname lname",
      timezone: 5.5,
      updated_time: "2012-06-08T13:09:47+0000",
      username: "fname.lname",
      verified: true,
      followers_count: 100,
      friends_count: 1000,
      created_at: "2017-06-08T13:09:47+0000",
    ),
  )

  OMNIAUTH_BASIC_INFO = {
    uid: SecureRandom.hex(3),
    info: OMNIAUTH_INFO,
    extra: OMNIAUTH_EXTRA_INFO,
    credentials: {
      token: SecureRandom.hex,
      secret: SecureRandom.hex
    }
  }.freeze

  OMNIAUTH_PAYLOAD_FACEBOOK = OmniAuth::AuthHash::InfoHash.new(
    {
      provider: "facebook",
      uid: SecureRandom.hex,
      info: {
        email: "markz@thefacebook.com",
        name: "fname lname",
        image: "https://dummyimage.com/400x400.jpg",
        urls: { "Facebook" => "https://example.com" }
      },
      credentials: {
        token: SecureRandom.hex,
        refresh_token: SecureRandom.hex,
        expires_at: 1_589_475_606,
        expires: true
      },
      extra: {
        raw_info: {
          email: "markz@thefacebook.com",
          id: "123455677",
          name: "fname lname"
        }
      }
    },
  ).freeze

  OMNIAUTH_PAYLOAD_APPLE = OmniAuth::AuthHash::InfoHash.new(
    {
      provider: "apple",
      uid: SecureRandom.hex,
      info: {
        sub: "001551.6fb185533f63469196d61e2ae126febf.1523",
        email: "hynnu385xiabcdef@privaterelay.appleid.com",
        first_name: "fname",
        last_name: "lname"
      },
      credentials: {
        token: SecureRandom.hex,
        refresh_token: SecureRandom.hex,
        expires_at: 1_589_475_606,
        expires: true
      },
      extra: {
        raw_info: {
          iss: "https://appleid.apple.com",
          aud: "test",
          exp: 1_589_472_606,
          iat: 1_589_472_606,
          sub: "001551.6fb185533f63469196d61e2ae126febf.1523",
          at_hash: SecureRandom.hex,
          email: "hynnu385xiabcdef@privaterelay.appleid.com",
          email_verified: true,
          is_private_email: true,
          nonce_supported: true,
          name: {
            first_name: "fname",
            last_name: "lname"
          },
          id_info: {
            auth_time: 1_589_472_002
          }
        }
      }
    },
  ).freeze

  def omniauth_setup_invalid_credentials(provider)
    OmniAuth.config.mock_auth[provider] = :invalid_credentials
  end

  def omniauth_setup_authentication_error(error, params = nil)
    # this hack is needed due to a limitation in how OmniAuth handles
    # failures in mocked/testing environments,
    # see <https://github.com/omniauth/omniauth/issues/654#issuecomment-610851884>
    # for more details
    local_failure_handler = lambda do |env|
      env["omniauth.error"] = error
      env["omniauth.params"] = params unless params.nil?
      env
    end

    # here we compose the two handlers into a single function,
    # the result will be global_failure_handler(local_failure_handler(env))
    failure_handler = local_failure_handler >> OMNIAUTH_DEFAULT_FAILURE_HANDLER

    OmniAuth.config.on_failure = failure_handler
  end

  def omniauth_failure_args(error, provider, params)
    class_name = error.present? ? error.class.name : ""

    [
      { tags: [
        "class:#{class_name}",
        "message:#{error&.message}",
        "reason:#{error.try(:error_reason)}",
        "type:#{error.try(:error)}",
        "uri:#{error.try(:error_uri)}",
        "provider:#{provider}",
        "origin:",
        "params:#{params}",
      ] },
    ]
  end

  def omniauth_mock_providers_payload
    Authentication::Providers.available.each do |provider_name|
      public_send("omniauth_mock_#{provider_name}_payload")
    end
  end

  def omniauth_reset_mock
    Authentication::Providers.available.each do |provider_name|
      OmniAuth.config.mock_auth[provider_name] = nil
    end
  end

  def omniauth_mock_facebook_payload
    OmniAuth.config.mock_auth[:facebook] = OMNIAUTH_PAYLOAD_FACEBOOK.dup
  end

  def omniauth_mock_apple_payload
    OmniAuth.config.mock_auth[:apple] = OMNIAUTH_PAYLOAD_APPLE.dup
  end

  def omniauth_mock_github_payload
    info = OMNIAUTH_BASIC_INFO[:info].merge(
      image: "https://dummyimage.com/400x400.jpg",
      urls: { "GitHub" => "https://example.com" },
    )

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      OMNIAUTH_BASIC_INFO.merge(
        provider: "github",
        info: info,
      ),
    )
  end

  def omniauth_mock_twitter_payload
    info = OMNIAUTH_BASIC_INFO[:info].merge(
      image: "https://dummyimage.com/400x400_normal.jpg",
      urls: { "Twitter" => "https://example.com" },
    )

    extra = OMNIAUTH_BASIC_INFO[:extra].merge(
      access_token: "value",
    )

    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
      OMNIAUTH_BASIC_INFO.merge(
        provider: "twitter",
        info: info,
        extra: extra,
      ),
    )
  end
end
