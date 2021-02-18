module Users
  class RemoveRole
    attr_reader :user, :role, :resource_type, :current_user, :response

    Response = Struct.new(:success, :error_message, keyword_init: true)

    def self.call(*args)
      new(*args).call
    end

    def initialize(user, _role, _resource_type)
      @user = user
      @role = params[:role].to_sym
      @resource_type = params[:resource_type]
    end

    def call
      return response if super_admin?(role)
      return response if current_user?(user)
    end

    private

    def super_admin?(role)
      return false if role != :super_admin

      response.error_message = "Super Admin roles cannot be removed."
      true
    end

    def current_user?(user)
      return false if user.id != current_user.id

      response.error_message = "Admins cannot remove roles from themselves."
      true
    end
  end
end
