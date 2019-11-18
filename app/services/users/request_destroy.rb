module Users
  module RequestDestroy
    module_function

    def call(user)
      token = SecureRandom.hex(10)
      user.update!(destroy_token: token)
      NotifyMailer.account_deletion_requested_email(user).deliver
    end
  end
end
