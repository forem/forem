module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    SUPER_ADMIN_ONLY_RESOURCES = %w[OrganizationPageManagement].freeze

    def index
      role_ids = admin_role_ids
      @users = if role_ids.empty?
                 User.none.page(params[:page]).per(50)
               else
                 User.where(id: UserRole.where(role_id: role_ids).select(:user_id))
                   .select(:id, :username, :profile_image)
                   .preload(:roles)
                   .order(:id)
                   .page(params[:page])
                   .per(50)
               end
    end

    def grant
      user = User.find_by(username: params[:username].to_s.delete("@").strip)
      role_parts = params[:role_name].to_s.split("|")
      role_name = role_parts[0]
      resource_type = role_parts[1]
      return refuse_super_admin_only unless assignable?(role_name, resource_type)

      if user && %w[admin super_admin tech_admin single_resource_admin].include?(role_name)
        if resource_type.present? && role_name == "single_resource_admin"
          begin
            resource_class = resource_type.constantize
            user.add_role(role_name, resource_class)
          rescue NameError
            user.add_role(role_name)
          end
        else
          user.add_role(role_name)
        end
        flash[:success] = "Granted #{params[:role_name]} to #{user.username}"
      else
        flash[:error] = "Invalid user or role"
      end

      redirect_to admin_permissions_path, status: :see_other
    end

    def revoke
      user = User.find_by(id: params[:user_id])
      role_parts = params[:role_name].to_s.split("|")
      role_name = role_parts[0]
      resource_type = role_parts[1]
      return refuse_super_admin_only unless assignable?(role_name, resource_type)

      if user && %w[admin super_admin tech_admin single_resource_admin].include?(role_name)
        if resource_type.present? && role_name == "single_resource_admin"
          begin
            resource_class = resource_type.constantize
            user.remove_role(role_name, resource_class)
          rescue NameError
            user.remove_role(role_name)
          end
        else
          user.remove_role(role_name)
        end
        flash[:success] = "Revoked #{params[:role_name]} from #{user.username}"
      else
        flash[:error] = "Invalid user or role"
      end

      redirect_to admin_permissions_path, status: :see_other
    end

    private

    def assignable?(role_name, resource_type)
      return true unless role_name == "single_resource_admin" && SUPER_ADMIN_ONLY_RESOURCES.include?(resource_type)

      current_user.super_admin?
    end

    def refuse_super_admin_only
      flash[:error] = "Only super admins can grant or revoke #{params[:role_name]}"
      redirect_to admin_permissions_path, status: :see_other
    end

    def admin_role_ids
      Role.where(name: %w[admin super_admin], resource_type: nil, resource_id: nil)
        .or(Role.where(name: "single_resource_admin"))
        .ids
    end
  end
end
