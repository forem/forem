class Net::SMTP
  class AuthPlain < Net::SMTP::Authenticator
    auth_type :plain

    def auth(user, secret)
      finish('AUTH PLAIN ' + base64_encode("\0#{user}\0#{secret}"))
    end
  end
end
