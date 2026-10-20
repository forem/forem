module CommunityLeaders
  # Revokes any community leader role from a user.
  class Remove
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def self.call(user)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      changed = false

      CommunityLeaders::ROLES.each do |role|
        if user.roles.exists?(name: role.to_s)
          user.remove_role(role)
          changed = true
        end
      end

      if changed
        # Bust user info cache
        user.touch
        # And remove leader icon from user's articles
        Users::ResaveArticlesWorker.perform_async(user.id)
      end

      Result.new(success?: true)
    end

    private

    attr_reader :user
  end
end
