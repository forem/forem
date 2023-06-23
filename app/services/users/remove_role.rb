module Users
  class RemoveRole
    Response = Struct.new(:success, :error_message, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(user:, role:, resource_type:, admin:)
      @user = user
      @role = role
      @resource_type = resource_type&.safe_constantize
      @admin = admin
      @response = Response.new(success: false)
    end

    def call
      return response if user_current_user?(user)

      if resource_type && user.remove_role(role, resource_type)
        response.success = true
      elsif user.remove_role(role)
        response.success = true
      end
      response
    rescue StandardError => e
      response.error_message = I18n.t("services.users.remove_role.error", e_message: e.message)
      response
    end

    private

    attr_reader :user, :role, :resource_type, :admin, :response

    def user_current_user?(user)
      return false if user.id != admin.id

      response.error_message = I18n.t("services.users.remove_role.remove_self")
      true
    end
  end
end
