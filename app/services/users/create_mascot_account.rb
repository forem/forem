module Users
  class CreateMascotAccount
    MASCOT_PASSWORD = SecureRandom.hex.freeze

    def self.call
      new.call
    end

    def self.mascot
      {
        email: "mascot@forem.com",
        username: "mascot",
        name: I18n.t("create_mascot.name"),
        profile_image: Settings::General.mascot_image_url,
        confirmed_at: Time.current,
        registered_at: Time.current,
        password: MASCOT_PASSWORD
      }.freeze
    end

    def call
      raise I18n.t("create_mascot.error") if Settings::General.mascot_user_id

      mascot = User.create!(mascot_params)
      Settings::General.mascot_user_id = mascot.id
    end

    def mascot_params
      # Set the password_confirmation
      self.class.mascot.merge(password_confirmation: self.class.mascot[:password])
    end
  end
end
