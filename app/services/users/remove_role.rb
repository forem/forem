module Users
  class RemoveRole
    Response = Struct.new(:success, :error_message, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(user:, role:, resource_type:, resource_id: nil)
      @user = user
      @role = role
      @resource_type = resource_type&.safe_constantize
      @resource_id = resource_id
      @response = Response.new(success: false)
    end

    def call
      resource = resource_id ? resource_type.find(resource_id) : resource_type
      if resource && user.remove_role(role, resource)
        response.success = true
        resource.touch if resource.respond_to?(:touch)
      elsif user.remove_role(role)
        response.success = true
        if community_leader_role?
          user.touch
          Users::ResaveArticlesWorker.perform_async(user.id)
        end
      end
      user.profile.touch
      response
    rescue StandardError => e
      response.error_message = I18n.t("services.users.remove_role.error", e_message: e.message)
      response
    end

    private

    attr_reader :user, :role, :resource_type, :resource_id, :response

    def community_leader_role?
      role_name = role.respond_to?(:name) ? role.name : role.to_s
      CommunityLeaders::ROLES.map(&:to_s).include?(role_name)
    end
  end
end
