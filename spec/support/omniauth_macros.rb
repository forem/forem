module OmniauthMacros
  INFO = OmniAuth::AuthHash::InfoHash.new(
    first_name: "fname",
    last_name: "lname",
    location: "location,state,country",
    name: "fname lname",
    nickname: "fname.lname",
    email: "yourname@email.com",
    verified: true,
  )

  EXTRA_INFO = Hashie::Mash.new(
    raw_info: Hashie::Mash.new(
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

  CREDENTIAL = OmniAuth::AuthHash::InfoHash.new(
    token: "2735246777-jlOnuFlGlvybuwDJfyrIyESLUEgoo6CffyJCQUO",
    secret: "o0cu6ACtypMQfLyWhme3Vj99uSds7rjr4szuuTiykSYcN",
  )

  BASIC_INFO = {
    uid: "1234567",
    info: INFO,
    extra: EXTRA_INFO,
    credentials: CREDENTIAL
  }.freeze

  def mock_twitter_with_invalid_credentials
    OmniAuth.config.mock_auth[:twitter] = :invalid_credentials
  end

  def setup_omniauth_error(error)
    # this hack is needed due to a limitation in how OmniAuth handles
    # failures in mocked/testing environments,
    # see <https://github.com/omniauth/omniauth/issues/654#issuecomment-610851884>
    # for more details
    global_failure_handler = OmniAuth.config.on_failure

    local_failure_handler = lambda do |env|
      env["omniauth.error"] = error
      env
    end
    # here we compose the two handlers into a single function,
    # the result will be global_failure_handler(local_failure_handler(env))
    failure_handler = local_failure_handler >> global_failure_handler

    OmniAuth.config.on_failure = failure_handler
  end

  def mock_auth_hash
    mock_twitter
    mock_github
  end

  def mock_twitter
    info = BASIC_INFO[:info].merge(
      image: "https://dummyimage.com/400x400_normal.jpg",
    )

    extra = BASIC_INFO[:extra].merge(
      access_token: "value",
    )

    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
      BASIC_INFO.merge(
        provider: "twitter",
        info: info,
        extra: extra,
      ),
    )
  end

  def mock_github
    info = BASIC_INFO[:info].merge(
      image: "https://dummyimage.com/400x400.jpg",
    )

    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      BASIC_INFO.merge(
        provider: "github",
        info: info,
      ),
    )
  end
end
