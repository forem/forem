module Users
  class UsernameGenerator
    def self.call(...)
      new(...).call
    end

    def initialize(user)
      @user = user
    end

    def call
      username = from_auth_providers
      return username if username.present? && !username_exists?(username)

      3.times do
        username = random_letters

        break unless username_exists?(username)

        username = nil
      end

      username
    end

    private

    # @todo bit heavy check, maybe keep all usernames in redis?
    def username_exists?(username)
      User.exists?(username: username) ||
        Organization.exists?(slug: username) ||
        Page.exists?(slug: username) ||
        Podcast.exists?(slug: username)
    end

    def from_auth_providers
      provider = Authentication::Providers.username_fields.detect { |u| @user.public_send(u).present? }
      provider_username = @user.public_send(provider)
      provider_username.downcase.gsub(/[^0-9a-z_]/i, "").delete(" ") if provider_username
    end

    def random_letters
      ("a".."z").to_a.sample(12).join
    end
  end
end
