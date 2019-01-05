module OmniauthMacros
  INFO = OmniAuth::AuthHash::InfoHash.new(
    first_name: "fname",
    last_name: "lname",
    location: "location,state,country",
    name: "fname lname",
    nickname: "fname.lname",
    email: "yourname@email.com",
    verified: true,
    # info.image = "http://graph.facebook.com/123456/picture?type=square&#8221"
  )

  EXTRA_INFO = Hashie::Mash.new(raw_info: Hashie::Mash.new(
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
  ))

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

  def mock_auth_hash
    mock_twitter
    mock_github
  end

  def mock_twitter
    OmniAuth.config.mock_auth[:twitter] = OmniAuth::AuthHash.new(
      BASIC_INFO.merge(provider: "twitter"),
    )
  end

  def mock_github
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      BASIC_INFO.merge(provider: "github"),
    )
  end
end
