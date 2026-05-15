module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    def index
      @users = User.with_role(:admin)
        .union(User.with_role(:super_admin))
        .union(User.with_role(:single_resource_admin, :any))
        .page(params[:page])
        .per(50)
    end

    def grant
      user = User.find_by(username: params[:username].to_s.gsub("@", "").strip)
      role_parts = params[:role_name].to_s.split("|")
      role_name = role_parts[0]
      resource_type = role_parts[1]

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
  end
end
