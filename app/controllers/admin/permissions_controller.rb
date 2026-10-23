module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    GRANTABLE_ROLES = %w[admin super_admin tech_admin single_resource_admin].freeze

    def index
      @users = User.with_role(:admin)
        .union(User.with_role(:super_admin))
        .union(User.with_role(:single_resource_admin, :any))
        .page(params[:page])
        .per(50)
    end

    def grant
      user = User.find_by(username: params[:username].to_s.gsub("@", "").strip)
      role_name, resource_type, scoped_role_name = params[:role_name].to_s.split("|")

      if user && GRANTABLE_ROLES.include?(role_name) && valid_role_scope?(role_name, resource_type, scoped_role_name)
        if role_scope?(role_name, resource_type)
          # The scoped role's record may not exist yet if nobody holds that role
          scoped_role = Role.global.find_or_create_by!(name: scoped_role_name)
          user.add_role(role_name, scoped_role)
        elsif resource_type.present? && role_name == "single_resource_admin"
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
      role_name, resource_type, scoped_role_name = params[:role_name].to_s.split("|")

      if user && GRANTABLE_ROLES.include?(role_name) && valid_role_scope?(role_name, resource_type, scoped_role_name)
        if role_scope?(role_name, resource_type)
          scoped_role = Role.global.find_by(name: scoped_role_name)
          user.remove_role(role_name, scoped_role) if scoped_role
        elsif resource_type.present? && role_name == "single_resource_admin"
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

    def role_scope?(role_name, resource_type)
      role_name == "single_resource_admin" && resource_type == "Role"
    end

    # A Role scope ("single_resource_admin|Role|base_subscriber") must name one
    # specific role from Constants::Role::RESOURCE_ADMIN_SCOPABLE_ROLES; a
    # class-level Role scope would cover every role.  Every other value keeps
    # its existing handling.
    def valid_role_scope?(role_name, resource_type, scoped_role_name)
      return true unless role_scope?(role_name, resource_type)

      Constants::Role::RESOURCE_ADMIN_SCOPABLE_ROLES.include?(scoped_role_name)
    end
  end
end
