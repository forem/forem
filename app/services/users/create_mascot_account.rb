module Users
  class CreateMascotAccount
    MASCOT_PARAMS = {
      email: "mascot@forem.com",
      username: "mascot",
      profile_image: Settings::General.mascot_image_url,
      confirmed_at: Time.current,
      registered_at: Time.current,
      password: SecureRandom.hex
    }.freeze

    def self.call
      new.call
    end

    def call
      raise I18n.t("create_mascot.error") if Settings::General.mascot_user_id

      mascot = User.create!(mascot_params)
      Settings::General.mascot_user_id = mascot.id
    end

    def mascot_params
      # Set the password_confirmation and i18n name
      MASCOT_PARAMS.merge(
        name: I18n.t("create_mascot.name"),
        password_confirmation: MASCOT_PARAMS[:password],
      )
    end
  end
end
