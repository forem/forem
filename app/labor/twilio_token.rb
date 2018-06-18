class TwilioToken
  attr_accessor :user, :room_name

  def initialize(user, room_name)
    @user = user
    @room_name = room_name
  end

  def get
    # Replace with ENV vars
    account_sid = ENV["TWILIO_ACCOUNT_SID"]
    api_key = ENV["TWILIO_VIDEO_API_KEY"]
    api_secret = ENV["TWILIO_VIDEO_API_SECRET"]

    token = Twilio::JWT::AccessToken.new(
      account_sid,
      api_key,
      api_secret,
      [],
      identity: user.id
    )

    grant = Twilio::JWT::AccessToken::VideoGrant.new
    grant.room = room_name
    token.add_grant(grant)

    token.to_jwt
  end

end