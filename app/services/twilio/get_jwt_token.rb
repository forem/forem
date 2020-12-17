module Twilio
  class GetJwtToken
    def self.call(user, room_name)
      token = Twilio::JWT::AccessToken.new(
        ApplicationConfig["TWILIO_ACCOUNT_SID"],
        ApplicationConfig["TWILIO_VIDEO_API_KEY"],
        ApplicationConfig["TWILIO_VIDEO_API_SECRET"],
        [],
        identity: user.id,
      )

      grant = Twilio::JWT::AccessToken::VideoGrant.new
      grant.room = room_name
      token.add_grant(grant)

      token.to_jwt
    end
  end
end
