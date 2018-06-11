class TwilioToken
  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def get
    require 'twilio-ruby'

    # Replace with ENV vars
    account_sid = 'AC1403f2c95cd4912bcb13e1fdc893aef1'
    api_key = 'SK02d79fd84d84df170adce9a95f826c0d'
    api_secret = 'MQC9HvLDMbwyQTJNs3x1IHNodidq2Zqf'

    token = Twilio::JWT::AccessToken.new(
      account_sid,
      api_key,
      api_secret,
      [],
      identity: user.id
    )

    grant = Twilio::JWT::AccessToken::VideoGrant.new
    grant.room = 'DailyStandup'
    token.add_grant(grant)

    token.to_jwt
  end

end