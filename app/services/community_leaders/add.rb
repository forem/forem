module CommunityLeaders
  # Grants a user a community leader role. A user can only hold one community
  # leader role at a time.
  class Add
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def self.call(user, role)
      new(user, role).call
    end

    def initialize(user, role)
      @user = user
      @role = role
    end

    def call
      unless CommunityLeaders::ROLES.include?(role)
        return Result.new(success?: false, errors: "Invalid community leader role: #{role}")
      end

      # Do nothing if the user already has the role
      return Result.new(success?: true) if user.roles.exists?(name: role.to_s)

      swap_to(role)

      # TODO: send updated community-leader onboarding email
      user.add_role(:trusted) unless user.roles.exists?(name: "trusted")

      # Bust user info cache
      user.touch

      Result.new(success?: true)
    end

    private

    attr_reader :user, :role

    def swap_to(role)
      CommunityLeaders::ROLES.each do |existing_role|
        next if existing_role == role
        next unless user.roles.exists?(name: existing_role.to_s)

        user.remove_role(existing_role)
      end
      user.add_role(role)
    end
  end
end
