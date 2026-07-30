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
      CommunityLeaders::ROLES.each do |role|
        user.remove_role(role) if user.roles.exists?(name: role.to_s)
      end
      Result.new(success?: true)
    end

    private

    attr_reader :user
  end
end
