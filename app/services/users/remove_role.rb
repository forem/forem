module Users
  class RemoveRole
    Response = Struct.new(:success, :error_message, keyword_init: true)

    def self.call(*args)
      new(*args).call
    end

    def initialize(user:, role:, resource_type:, admin:)
      @user = user
      @role = role
      @resource_type = resource_type&.safe_constantize
      @admin = admin
      @response = Response.new(success: false)
    end

    def call
      return response if super_admin_role?(role)
      return response if user_is_current_user?(user)

      if resource_type && user.remove_role(role, resource_type)
        response.success = true
      elsif user.remove_role(role)
        response.success = true
      end
      response
    rescue StandardError => e
      response.error_message = "There was an issue removing this role. #{e.message}"
      response
    end

    private

    attr_reader :user, :role, :resource_type, :admin, :response

    def super_admin_role?(role)
      return false if role != :super_admin

      response.error_message = "Super Admin roles cannot be removed."
      true
    end

    def user_is_current_user?(user)
      return false if user.id != admin.id

      response.error_message = "Admins cannot remove roles from themselves."
      true
    end
  end
end
