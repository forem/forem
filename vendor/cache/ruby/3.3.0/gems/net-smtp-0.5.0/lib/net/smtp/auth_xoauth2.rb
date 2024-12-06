class Net::SMTP
  class AuthXoauth2 < Net::SMTP::Authenticator
    auth_type :xoauth2

    def auth(user, secret)
      token = xoauth2_string(user, secret)

      finish("AUTH XOAUTH2 #{base64_encode(token)}")
    end

    private

    def xoauth2_string(user, secret)
      "user=#{user}\1auth=Bearer #{secret}\1\1"
    end
  end
end
