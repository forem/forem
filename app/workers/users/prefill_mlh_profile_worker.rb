module Users
  # Fills in profile details from MLH. Does not overwrite set fields.
  class PrefillMlhProfileWorker
    include Sidekiq::Job
    sidekiq_options queue: :medium_priority, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      identity = user.identities.find_by(provider: "mlh")
      return if identity&.token.blank?

      mapped = Mlh::UserProfile.call(identity.token)
      return if mapped.blank?

      attributes = assignable_attributes(user, mapped)
      return if attributes.blank?

      Users::Update.call(user, profile: attributes)
    rescue Mlh::ApiClient::ClientError
      # Do not retry unrecoverable client errors
      nil
    end

    private

    # Filter out fields that already have values
    def assignable_attributes(user, mapped)
      profile = user.profile || user.create_profile

      mapped.select { |attribute, _value| profile.public_send(attribute).blank? }
    end
  end
end
