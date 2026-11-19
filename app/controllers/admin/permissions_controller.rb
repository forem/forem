module Admin
  class PermissionsController < Admin::ApplicationController
    layout "admin"

    SUPER_ADMIN_ONLY_RESOURCES = Constants::Role::SUPER_ADMIN_ONLY_RESOURCE_TYPES

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
      @sub_permissions = restricted_grants(@users.map(&:id))
    end

    def grant
      user = User.find_by(username: params[:username].to_s.delete("@").strip)
      mutate_role(user: user, mutation: :add_role, success_verb: "Granted", preposition: "to")
    end

    def revoke
      user = User.find_by(id: params[:user_id])
      mutate_role(user: user, mutation: :remove_role, success_verb: "Revoked", preposition: "from")
    end

    def sub_permissions
      user = User.find_by(id: params[:user_id])
      role_name, resource_type = params[:role_name].to_s.split("|", 2)
      resource_class = resolve_resource_class(resource_type)
      return refuse_super_admin_only unless assignable?(role_name, resource_type, resource_class)

      unless user && role_name == SubPermissions::ROLE_NAME && resource_class
        flash[:error] = "Invalid user or role" # rubocop:disable Rails/I18nLocaleTexts
        return redirect_to admin_permissions_path, status: :see_other
      end

      unless %w[0 1].include?(params[:restricted])
        flash[:error] = I18n.t("lib.sub_permissions.errors.mode_required")
        return redirect_to admin_permissions_path, status: :see_other
      end

      allow = params[:allow].is_a?(Array) ? params[:allow] : []
      config = params[:restricted] == "1" ? SubPermissions.build(allow: allow) : nil
      result = SubPermissions.update_grant(user: user, resource_type: resource_class.name, sub_permissions: config)

      if result.success?
        audit_payload = {
          "action" => "update_sub_permissions",
          "target_user_id" => user.id,
          "resource_type" => resource_class.name,
          "sub_permissions" => config
        }
        Audit::Logger.log(:internal, current_user, audit_payload)
        flash[:success] = I18n.t("lib.sub_permissions.admin.updated",
                                 resource: resource_class.name, username: user.username)
      else
        flash[:error] = result.errors.to_sentence
      end

      redirect_to admin_permissions_path, status: :see_other
    end

    private

    def mutate_role(user:, mutation:, success_verb:, preposition:)
      role_name, resource_type = params[:role_name].to_s.split("|", 2)
      resource_class = resolve_resource_class(resource_type)
      return refuse_super_admin_only unless assignable?(role_name, resource_type, resource_class)

      if user && valid_role_target?(role_name, resource_class)
        if role_name == "single_resource_admin"
          user.public_send(mutation, role_name, resource_class)
        else
          user.public_send(mutation, role_name)
        end
        flash[:success] = "#{success_verb} #{params[:role_name]} #{preposition} #{user.username}"
      else
        flash[:error] = "Invalid user or role" # rubocop:disable Rails/I18nLocaleTexts
      end

      redirect_to admin_permissions_path, status: :see_other
    end

    def resolve_resource_class(resource_type)
      return if resource_type.blank?

      constant = resource_type.strip.safe_constantize
      constant if constant.is_a?(Class)
    end

    def valid_role_target?(role_name, resource_class)
      return false unless %w[admin super_admin tech_admin single_resource_admin].include?(role_name)
      return true unless role_name == "single_resource_admin"

      resource_class.present? && Rolify.resource_types.include?(resource_class.name)
    end

    def assignable?(role_name, resource_type, resource_class)
      return true unless role_name == "single_resource_admin"
      return current_user.super_admin? if resource_type.blank?

      resolved_name = resource_class&.name || resource_type.to_s.strip.delete_prefix("::")
      return true unless SUPER_ADMIN_ONLY_RESOURCES.include?(resolved_name)

      current_user.super_admin?
    end

    def refuse_super_admin_only
      flash[:error] = "Only super admins can grant or revoke #{params[:role_name]}"
      redirect_to admin_permissions_path, status: :see_other
    end

    def restricted_grants(user_ids)
      return {} if user_ids.empty?

      UserRole.joins(:role)
        .where(user_id: user_ids)
        .where(roles: { name: SubPermissions::ROLE_NAME, resource_type: SubPermissions::CLAUSES.keys })
        .where(roles: { resource_id: nil })
        .where.not(sub_permissions: nil)
        .pluck(:user_id, "roles.resource_type", :sub_permissions)
        .to_h { |user_id, resource_type, config| [[user_id, resource_type], config] }
    end

    def admin_role_ids
      Role.where(name: %w[admin super_admin], resource_type: nil, resource_id: nil)
        .or(Role.where(name: "single_resource_admin"))
        .ids
    end
  end
end
