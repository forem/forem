module Users
  class CreateMascotAccount
    MASCOT_PARAMS = {
      email: "mascot@forem.com",
      username: "mascot"
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
      password = SecureRandom.hex
      now = Time.current

      # Set the password_confirmation, profile_image, timestamps, and i18n name lazily
      # so class loading does not trigger database queries or asset URL helpers at boot.
      MASCOT_PARAMS.merge(
        name: I18n.t("create_mascot.name"),
        profile_image: Settings::General.mascot_image_url,
        confirmed_at: now,
        registered_at: now,
        password: password,
        password_confirmation: password,
      )
    end
  end
end
