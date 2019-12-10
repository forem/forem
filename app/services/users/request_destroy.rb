module Users
  module RequestDestroy
    module_function

    def call(user)
      token = SecureRandom.hex(10)
      Rails.cache.write("user-destroy-token-#{user.id}", token, expires_in: 12.hours)
      NotifyMailer.account_deletion_requested_email(user, token).deliver
    end
  end
end
